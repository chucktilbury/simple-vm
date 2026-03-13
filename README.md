# Simple VM
This is a simple Virtual Machine implementation with an assembler and a dumper. It is not intended for any real work. It is a toy and eventually I may port a small C compiler to it. **Funfun**.

## VM Architecture

Simple register based virtual machine that closely resembles a simple microprocessor. The instruction set is minimal, but an interface is provided to connect arbitrary library routines to the VM itself. There is exactly one data type, which is a 64 bit signed integer. All registers and stack objects are of that type. They can be interpreted by library routines. When the VM loads the binary image of the program to run, first it allocates the registers. Then it loads the data store after that. The first entry in the data store has an index of 33. Then the VM initializes the stack after the data store. If there are 10 items in the data store, then the top of the stack will be ``33 + 10 + 1 = 44``.

There are 32 registers with a stack pointer that are all accessed in exactly the same way. Registers are numbered from 1 to 32 where R32 is an alias for the SP.

The stack is an array of signed 64 bit integers and the stack pointer is an index to the array. Things like function parameters and local variables are/can be stored on the stack and the return address for a ``CALL`` instruction is also stored there. The ``RET`` instruction pops the value at the top of the stack directly into the instruction pointer when it is encountered. The stack pointer value is directly accessible by some instructions, such as the ``MOV`` instruction, but not from others, such as ``ADD``. The value that the stack pointer points to is directly accessible as any other register. When the data store is loaded from disk, the top of the stack is set to the end of it to allow the stack and the data store to operate from a register. The stack grows up in value and there is no specific limit on it's size.

The memory store is an array of 64 bit signed integers. It is accessed using an index into that array, starting at index zero. All memory is read/write. There is no notion of read-only memory.

The instruction store is an array of unsigned bytes and the instruction pointer is an index into the array. Invalid or unknown instructions raise an exception internally to the VM, publishes an error to ``stderr`` and aborts the VM. There is no way of directly accessing the instruction pointer or the value that the pointer references. Only flow control instructions such as ``CALL`` and ``RET`` can set the value. However those instructions can accept an indirect reference such as ``CALL R21[R0]``. In this example, the value in ``R21`` as added to the value in ``R0`` to find the absolute address to call to. All addresses given are absolute and no "relative" jumps are allowed.

## Assembler

### Input File Layout

The assembler is a single-pass compiler that is as simple as possible. All symbols in the input must be fully defined before referencing. That having been said, data and code can be defined anywhere in the input and they are emitted separately as a single binary with the names stripped out. The names in the data and code are replaced with their indexes by the assembler. 

The assembler is designed to support the C preprocessor. All lines that begin with a ``#`` are ignored as comments. No attempt is made to track source code line numbers and whatnot. It is intended that the heavy use of the ``#include`` directive will be made and ``#define`` macros will be very useful. All comment formats that are supported by the preprocessor are supported in the input. The preprocessor is automatically run by the assembler and the assembler operates on the result as a temporary file.

Most whitespace in the input is completely ignored. 

### Assembler Instructions

Assembler instructions are as simple as possible and designed for efficiency. Most instructions only accept registers. The most complicated instruction is the ``MOV`` instruction and it's designed to handle things like indirect addressing. In general, any register is acceptable for any instruction, including the stack pointer, ``SP``. However, the ``SP`` register refers to the stack item pointed to by the stack pointer. To access the actual value of the stack pointer itself, one must use the ``MOV`` which accesses all registers by its own semantic rules. (see below)

In general, the first operand of an instruction is the destination and the other operands are in expression order.

* **``sub dest,left,right``** -- The ``right`` operand is subtracted from the ``left`` operand and the result is placed in the ``dest`` operand. AKA ``dest=left-right``.

#### Example of stack manipulation
```
    // put some stuff on the stack
    mov  r30,0      // cannot push a literal directly, need to use mov to get it into a register
    push r30        // push 0 on the stack, sp++
    push r10        // push what is in R10, sp++
    mov  r30,sp     // put the actual value of SP into R30.
    sub  r30,r31,2  // change the value to point back to where it was when the 0 was pushed
    mov  sp,r30     // put the new value back into the SP
    add  sp,r12,10  // add 10 to the value of R12 and then save the result on the stack at the current SP
```

#### Directives

A directive is a word that controls the operation of the assembler, rather than directly produce output. 

* **``DATA``** -- This directive causes one or more memory store items to be created. 

#### Instructions

* **``MOVx``** -- This instruction facilitates moving literal data into the system. This data can be literal or from the data store. This is the only instruction that takes arguments other than a register. See this example:
    * Values for ``x``
        * **``MOV``**   // Two registers, right to left.
        * **``MOVI``**  // Register and an immediate value inline to the instruction stream.
        * **``MOVN``**  // Index is literal inline and refers to the data store.
        * **``MOVR``**  // Two registers where the second register has an index.
```
    mov r0,r1     // The value of R1 is copied to R0
    movi r0,0x123 // The literal value is copied to R0. The literal value is inline to the instruction stream
    movn r0,r1[]  // the contents of R1 is taken to be a data store index and the value at that index is copied to R0.
    movn r0,r1[0] // same as the above. Note that only literal values and registers are allowed in the [].
    movi r0,some_name // The name is taken to be a data store index and is translated to the form in the next line.
                    // If some_name is an instruction label then a syntax error. In the output the index is substituted for the name.
    movi r0,[123] // copy the value given by the 123'rd data index into R0.
                  // Negative value is a syntax error. A simple constant expression is allowed.
    movr r0,r1[123] // The value in R1 is an index into the data store and the literal is added to the index to create a new index.
    movr r0,r1[r2] // The value in R1 is an index into the data store and the contents of R2 is added to the index to create a new index.
    mov r0,sp      // The value of the stack pointer is copied to R0
    movn r0,sp[]   // The value of the top of the stack is copied to R0
    movn r0,sp[-1] // The value at the top of the stack - 1 is copied to R0
    movn r0,r1[-1] // The value at the location given by register R1 - 1 is copied to R0.

```
* **``PUSH/POP``** -- These instructions indirectly use the stack pointer to move data into the stack or free stack space.
    * **``PUSH R12``** --  Push the value that is in R12 on the stack.
    * **``POP R13``** -- Pop the top of the stack into R13.

* **``ADD/SUB/MUL/DIV/MOD``** -- Arithmetic instructions. Note that divide by zero results in a VM abort.
    * **``ADD R1,R2,R3``** -- Add the value in R2 and R3 and place the result in R1.

* **``CALLx/JMPx/RETx``** -- Flow control instructions can be unconditional or conditional.
    * Values for ``x``
        * **``T``** -- execute the instruction if the ``true-flag`` is SET.
        * **``F``** -- execute the instruction if the ``true-flag`` is CLEAR.
    * Examples
        * **``CALL R1``** -- Unconditionally call where R1 has the index into the instruction store.
        * **``CALL 1234``** -- Unconditionally call the location given by the inlined literal.
        * **``CALLT R1``** -- Call the index in R1 if the ``true-flag`` is set.
        * **``JMPF R1``** -- Jump to the index in R1 if the ``true-flag`` is clear.
        * **``RET R1``** -- Return from a call but first pop from the stack the value that is held in R1. If R1 has 2, the pop two value from the stack before returning.
        * **``RETT 5``** -- If the ``true-flag`` is set then pop 5 stack items into nothing and return from a call.

* **``LT/GT/LTE/GTE/EQ/NEQ``** -- Comparison instructions set the ``true-flag``, according to the comparison made.
    * **``LT R1,R2``** -- Set the ``true-flag`` if the value in R1 is less-than the value in R2.
    * **``NEQ R1,R2``** -- Set the ``true-flag`` if the value in R1 is not the same as the value in R2.
    
* **``SETF/CLRF``** -- Unconditionally set or clear the ``true-flag``. This is the only other way to control the ``true-flag`` besides the comparison instructions.=.
    * **``SETF``** -- Set the ``true-flag``.

* **``EXIT``** -- Exit the VM normally with all of the post-operation procedures intact.

* **``ABORT``** -- Terminate the VM and display the exception information.

* **``NOP``** -- No operation. This is used to pad code to do things like align it to a page.




