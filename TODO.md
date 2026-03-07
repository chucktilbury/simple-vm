# TODO list

## Refactoring the file format.

* Got rid of the "assembler functions" and replaced with a single instruction for an interface to external libraries. It accepts a quoted string that specifies the name of the function in C code. The internals of the VM that drive this interface have access to the registers and the stack. Note that any value can be placed into a register, including something like a pointer to stdout.

* Abandoned function definitions with automatic stack manipulations in favor of just doing it directly.

* Abandon the idea of using floats as "NUMBERS" and unsigned ints as "INDEXES". The VM does not need to know about a float, only external functions can use it. But note, once again, the VM does not monitor the content of registers.

* Adding the logic to flag exceptions for invalid code or data access. Other exceptions are divide by zero and NAN results. The exception table is set up from the VM code and is not accessible to the assembler. All exceptions are fatal errors. When an exception happens a core dump takes place where the instruction ad stack pointers are dumped along with all of the registers.
    * An invalid code access happens when an attempt to execute code outside of the currently defined code buffer happens. Part of the JMP and CALL handlers is checking for that.
    * An invalid data access happens when an attempt is made to write to the code segment. Note that the code buffer can be read by instructions.

* Think more about the instruction parameters and how they are implemented in the instruction stream. For example, is it better to put the immediate values such as numbers and strings in a separate segment? Or to put them inline in the instruction stream? I am putting them in a separate segment to try and keep the instruction scheme to a single byte.

**``There are 2 separate data segments.``**

* Instruction stream is a stream of bytes and indexes. An index is an unsigned 32 bit entity that gives an index into an array of data. An instruction index is always byte aligned.

* Variable data can be initialized or not, depending on the definition. This area is organized into an array of unsigned ints and is accessed using the array index, starting at zero. It is page-aligned. There is nothing in the assembler or the VM that judges the contents of the memory slots. Strings are stored as if in an array of unsigned ints with no padding of any kind.

**``Registers``**

Registers are labeled from **``R1 to R32``**. Every register is exactly the same. The register **``SP``** is the stack counter. Any operation that accepts a normal register can also accept the stack counter. The instruction counter is not directly accessible to any VM instruction.

**``Data types``**

As stated before al items in the data store are unsigned ints, but the instructions are capable of operating on different data types.

* Signed ints are used for relative instruction indexes.

* Float are used for some arithmetic instructions.

* Strings are treated as an array of unsigned bytes. These are not handled by any specific instruction but supported in the assembler for the sake of implementing external routines.

## Instruction parameters

An instruction parameter ultimately describes a register size entity that can be operated on by the instruction. How the parameter is used depends on the instruction associated with it. For example, if the instruction is a flow instruction, such as a **``CALL``** or **``JMP``** then the number is used as an index into the instruction stream. If the instruction is another kind of instruction then the value is taken as data. These values are taken as unsigned bit arrays. Any signed-ness is applied by the use of the value and the instruction associated with the parameter.

Any parameter form can appear for any parameter position with the caveat that the read/write status is observed. I.E. if the result would write to a memory slot, the value must reference a memory slot. The instruction stream is read-only.

**``Instruction parameters can have one of 3 forms.``**

* A reference to an actual value in a register. There is no way to know what type of data is in a register once it has been written. There are various ways to crash the system as a result. This is the most simple and fastest way to move data around.

* A register that holds a pointer (indirection) to an immediate value. The value in the register holds an index into the read/write memory store. For example a global number that can be written to **must** be in the read/write memory store.

* An immediate literal value. These values are inline to the instruction stream and are read as a 32 bit unsigned int. Same as a register, these values can be any arbitrary type.

**``A value that is held in a register can have one of 2 forms.``**

* The register by itself with no modifier. Can represent a data index, an instruction index, or a simple value.

    * **``examples``**
        * ``mov r1,r2 // The contents of r2 is copied into the contents of r1 without interpretation``

* The register itself with an index. The index syntax is an expression that is enclosed in **``[]``** characters. The expression value must be known at assembly time and the result is stored inline in the instruction stream as a register sized bit stream.

    * **``examples``**
        * ``mov r1,r2[0] // The contents of the memory slot in r2 is copied to the value of r1``
        * ``mov r1[0],r2 // The contents of r2 is copied to the the memory slot value of r1``
        * ``mov r1,r2[1+2+3] // The value of the expression is stored inline in the instruction stream and used to index r2 as an array`` Note that expressions must have a value at compile time.

## Instructions

An instruction is a byte code that the VM performs an action upon. The fall into 2 broad categories:

* Directives control the way the assembler or the VM itself operates.

* Instructions are operated upon directly by the VM.

**``Directives``**

* **``INCLUDE``** -- Cause the specified file to read into the input stream as if it was the current file. When the included file runs out, reading resumes with the original file at the byte where it left off before. No other distinction is made between included files and the one with the ``include`` directive. All global variables must be globally unique and should probably include some form of the file name to organize them.

    * ``include "some-file-name.a"``
    * ``include "/full/path/to/file.a"``

* **``DATA``** -- Introduce a name of a data element. This reserves a word in the global data store unless a form of array is specified in the definition.

    * ``data some_name // define a single memory slot``
    * ``data float_name = 0.123e-12 // reserve the slot and assign the float to it``
    * ``data array_name[10] // define an array of 10 memory slots``
    * ``data array_name = {10, 10, 10} // define an array of 3 slots, initialized to 10``
    * ``data string_name = "this is a string" // define an array of 4 slots, the last one being init to 0``

* **``EXTERN``** -- Do a **``CALL``** to an external function (such as libc or some other library) that is pre-defined in the VM.

```
    mov r1,3 // arity of the call
    mov r2,format_name // pointer to the format
    mov r3,parameter1 // value of 1st arg
    mov r4, parameter2 // value of 2nd arg
    extern "printf" // call libc printf() with a format and 2 parameters
```

**``Instructions``**

* **``MOV``** -- Place the value found on the right into the entity found on the left. The value on the left must be writable.

    * ``mov r01, 0x1234 // move the immediate value into register R1``

* **``PUSH``** -- Push the value in question on to the stack.

    * ``push r21 // Push the contents of r21 on the stack``
    * ``push 0x1234 // Push the immediate literal on the stack``

* **``POP``** -- Pop the top of the stack into the register.

    * ``pop r22 // pop the stack into r22``

* **``COPY``** -- Copy an array of memory words from one place to another. The first 2 parameters are pointers and the last one is a value. The index of the array starts at 0 and is incremented for each memory slot until the number of iterations is reached.

    * ``copy r1,r2,10 // copy 10 words from the index given in r2 into the index given by r1``

* **``ADDx/SUBx/MULx/DIVx/MODx``** -- Perform the specified arithmetic operation. The first parameter is the destination and it must be writable. The second and third parameters are the operands and can have any valid format. The **``x``** specifies the type of the result to create. If a cast is needed, then the VM will automatically handle it.

    * **``Valid values``**
        * **``I``** -- Performs the operation on signed integers.
        * **``U``** -- Performs the operation on unsigned integers.
        * **``F``** -- Performs the operation as on floats.

    * **``examples``**
        * ``addf r1,r2,10.123 // add the immediate value of 10.123 to the contents of r2 and place the result in R1``
        * ``mulf r1,r2,2 // aborts the VM because the value 0x02 is not a valid float``
        * ``subu r1,r2,2 // subtract 2 from the value in r2 as an unsigned and put the result in r1``

* **``CALLx/JMPx/RETx``** -- Control the flow by loading the instruction pointer with the result indicated by a single argument. The **``x``** specifies the condition that the instruction will be active for.

    * **``Valid values``**
        * Blank specifies an unconditional execution.
        * **``T``** -- Follow the control if the ``true flag`` is set.
        * **``F``** -- Follow the control if the ``true flag`` is clear.

    * **``examples``**
        * ``JMP some_name // Jump unconditionally to the location specified by the name``
        * ``RETT // Return if the true flag is set``
        * ``callf some_name // Call if the true flag is clear``

* **``LT/GT/LTE/GTE/EQ/NEQ``** -- Test instructions that set the true flag. Accepts two parameters and compares then as bit fields. If all of the bits are equal then the true flag is set. Otherwise it is cleared. Normal instructions do not change the flag.

    * ``gte r1,r2 // set the true flag is the result of (r1 <= r2) is true. Otherwise clear the flag.``

* **``SETF/CLRF``** -- Set or clear the true flag unconditionally.

* **``EXIT``** -- Cause the VM to end normally.

    * ``exit 0x02 // exit the VM and return the value 0x02 to the operating system.``

* **``ABORT``** -- Cause the VM to end and show the exception information.``

* **``NOP``** -- Pad the instruction stream with a "no-operation". This can be used to align the instruction stream onto a page boundary for performance.

