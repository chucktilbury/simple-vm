# Simple VM
This is a simple virtual machine implementation that includes a simple assembler for it. It's just for fun and not really intended for anything. I might hook up a small C or something at some point, depending on whether I am interested at the time. 

The VM is arranged like a processor with a stack, registers, load, store, compare, and arithmetic instructions. Provisions are also made for built in functions such as print and some file IO. 

The assembler is a separate program that writes a binary file that is loaded by the VM. It supports symbols and an ``include`` directive. It outputs a single, fully linked, file that is loaded by the VM for execution. 

A disassembler is also implemented to aid debugging. 

The VM memory model is transparent to the program. It supports ``alloc`` and ``free``, which are ultimately implemented using the C standard library. Also the assembler supports static data. 

VM data types.

* Address. A ``pointer`` of whatever format is defined by the operating system. An address can refer to a static memory or an allocated memory. If ``free`` is applied to a static address, it fails silently. All addresses reference data.
* Number. A number is a native ``double`` number.
* Index. An index is an ``unsigned long`` that is used to index a buffer.
* Buffer. This is an array of ``unsigned char`` bytes. Defining a buffer in the assembler refers to an assembler address. Note that all buffers are aligned on a 64 bit boundary and are a multiple of the size of an address, which is 8 under 64 bit Linux. 
* Label. The is an ``unsigned long`` that references the instruction buffer. 

There is no strict data type checking in the assembler or in the VM. The VM operates on registers and whatever is in the register is assumed to be what the instruction is operating on. A register in the VM is the same size as a ``long integer``, which is 8 bytes (64 bits on x86_64). Any of the data types will fit into that. 

The VM stack is push-up/pop-down and does not have a strict size limit. It is enlarged as required but is never de-allocated. All function calls use the stack for parameters and the return address of a function call is stored on the stack as well. Local data definitions are stored on the stack as well. The ``RET`` instruction accepts an ``INDEX`` that adjusts the stack to free a function call. After a function is entered, the stack is adjusted to accommodate what is on the stack. ``PUSH`` and ``POP`` instructions are permissible in a function definition. 

Note that there is no way to directly access the program counter or the stack pointer. 

All ``ADDRESS`` indirection is permissible. No checking is done for the wisdom of reading or writing with an address. See the instruction descriptions for using an index with an address. 

All variables defined outside of a function are defined in global initialized data. Code does not need to be defined inside of a function. All code that is defined outside of a function is executed in the order it is encountered. It is concatenated and stored at the beginning of the output binary it is entered when the VM begins execution. Code and data cannot be mingled, however, a ``LABEL`` value can be stored in global data. 

The instruction buffer is written and read as an array of bytes. Those bytes are arranged according to the endianess of the host. 

## VM Address Modes
An address mode is the way a register is referenced and it's encoding in the instruction steam. All instructions have the same format. In general executing an instruction does not destroy the operands.

### REG
A ``REG`` always references an internal register. There are 32 internal registers numbered 1 through 32. The address register and the stack pointer are excluded from all register access unless otherwise indicated.

* ``R12``
* ``R32``
* ``R1``

### INDEX
Is always an unsigned integer. Indexes are always used as if it is an index into an array of 64 bit entities, but the types of those entities is never checked. Note that the assembler will replace the name of a label or buffer with the correct index.

* ``REG``
* ``0`` -- Zero is always taken to be an INDEX
* ``0x123``
* ``1234``
    * Index arithmetic is supported.
        * ``REG+123``
        * ``123-REG``

### NUM
Is always a double precision floating point number.

* ``0.0`` -- Floating point "zero"
* ``1.0``
* ``0.1``
* ``0.123e-12``

### MODE1
Can be a register, a dereferenced address, or a literal index or number.

* ``REG``
* ``REG[INDEX]``
* ``INDEX``
* ``NUM``

### MODE2
Can be a register or a dereferenced address. It cannot be a literal.

* ``REG``
* ``REG[INDEX]``

### MODE3
Used as arguments to the math functions.

* ``REG``
* ``REG[INDEX]``
* ``NUM``

### MODE4
Used as arguments to the math functions.

* ``REG``
* ``REG[INDEX]``
* ``INDEX``

## VM Instructions

* **``MOVE MODE1,MODE2``** -- Copy the first operand to to the second operand.

* **``PUSH MODE1``** -- Push the value to the top of the stack and increment the stack pointer.

* **``POP``** -- Pop one or more items off of the stack.
    * **``POP REG``** -- Copy the value at the top of the stack to the operand and decrement the stack register.
    * **``POP INDEX``** -- Pop the literal INDEX number items off of the stack into nothing. Used to free locals allocated in a code block. If INDEX is 0 then this is the same as a NOP.

* **``COPY MODE3,MODE2,MODE2``** -- The first operand is the number of items to copy. The second operand is the source pointer that points to a buffer of 64 bit memory slots. The third operand is the destination buffer. The data is copied by the number of memory slots given by the first operand. As the copy happens the number of items is decremented to zero and the indexes of the source and destination buffers is incremented. Note that if there is an index given on the source of the destination, it is only used to access the memory slot the first time and whatever is there needs to be a pointer. No checking is done to verify that the operands have a valid value.

* **``ADD/SUB/MUL/DIV/MOD``** -- Arithmetic operations.
    * **``ADD MODE3,MODE3,MODE2``** -- Perform the operation on the two operands and place the result in the last argument.

* **``CALL``** -- Unconditionally call the LABEL given by the first argument.
    * **``CALL MODE4,MODE4``** --  Allocate stack space given by the second argument. When the call happens, the current address is pushed on the stack. The second argument is intended to account for the arity of the function all and adjusts the stack pointer such that PUSH does not clobber function parameters or local variables.
    * **``CALL MODE4``** -- Push the return value on the stack, but assume that the stack pointer will be handled explicitly to accommodate function variables and locals.

* **``JMP MODE4``** -- Unconditionally jump to the LABEL. 

* **``RET``** -- Unconditionally return from a function call. 
    * **``RET INDEX``** -- First POP the INDEX number of values into nothing and then POP the top of stack into the instruction pointer causing an unconditional JMP. Note that the RET instruction pops the return address every time, so the number that is given by the literal INDEX does not include that. The number will be equal to the number of function parameters. (it's arity)
    * **``RET``** -- POP the top of the stack directly into the instruction pointer without accounting for any arity number.

* **``CLT/CGT/CLTE/CGTE/CEQ/CNEQ``** -- Conditionally call based on the result of comparing the two registers. See the CALL instruction above.
    * **``CLT MODE1,MODE1,MODE4,INDEX``**
    * **``CGTE MODE1,MODE1,MODE4``**

* **``JLT/JGT/JLTE/JGTE/JEQ/JNEQ``** -- Conditionally jump based on the result of comparing the two registers. See the JMP instruction above.
    * **``JGT MODE1,MODE1,MODE4``**

* **``RLT/RGT/RLTE/RGTE/REQ/RNEQ``** -- Conditionally return from a function call. 
    * **``REQ MODE1,MODE1,INDEX``** -- First POP the INDEX number of values into nothing and then POP the top of stack into the instruction pointer causing an unconditional JMP.
    * **``RGTE MODE1,MODE1``** -- POP the top of the stack directly into the instruction pointer without accounting for any arity number.

* **``EXIT``** -- Return to the operating system.
    * **``EXIT INDEX``** -- With a literal exit code.
    * **``EXIT``** -- With exit code 0.

* **``NOP``** -- No operation. This takes up space and provides padding where it is needed.

## VM Internal Functions
These are functions that can be accessed by the VM but are executed in native code. These have syntax similar to instructions for efficiency. They are mostly functions from the standard C library. 

* **``PRINT``** -- Print a string from a format to the stdout of the host. 
    * **``PRI REG``** Where the register is printed as an unsigned long int.
    * **``PRN REG``** Where the register is printed as a floating point number.
    * **``PRS REG``** Where the register is a pointer to a simple zero-terminated string.
    * **``PRF INDEX,REG,REG``** The literal index is the number of arguments to ``printf()`` including the format. The first REG is a zero-terminated string for the format. The second REG is a pointer to a buffer that holds INDEX-1 arguments, each in one memory slot. 

* **``INP REG``** -- Input a string from std in and place a pointer to it in the register. This assumes that the buffer was allocated by the ALLOC function. Implemented but ``fgets()``. 

* **``OPENR REG,REG``** -- Open a file as read-only where the name is a zero-terminated string in the first REG and the pointer to the file is placed in the second REG. If the file cannot be opened then a VM exception is generated.

* **``OPENW REG,REG``** -- Open a file as read-write where the name is a zero-terminated string in the first REG and the pointer to the file is placed in the second REG. If the file cannot be opened then a VM exception is generated.

* **``CLOSE REG``** -- Close a file that was previously open. Generate a VM exception if the file handle is invalid.

* **``READ REG,REG,INDEX``** -- Read from a file who's handle is in the first REG, the buffer is in the second REG, and the literal INDEX is the number of BYTES to read.

* **``WRITE REG,REG,INDEX``** -- Write to a file who's handle is in the first REG, the buffer is in the second REG, and the literal INDEX is the number of BYTES to write.

* **``ALLOC REG,INDEX``** -- Allocate a memory buffer. Returns the pointer into the REG and the size is given by the INDEX. The returned buffer is "zeroed" out. Alloc is implemented with the system calloc() function and no heap management is performed by the VM.

* **``FREE REG``** -- Free a buffer that was previously allocated by ALLOC. The REG has the pointer that was allocated by the ALLOC function. If not, the runtime will throw an exception.

* **``SIN/COS/TAN/ASIN/ACOS/ATAN/SINH/COSH/TANH/EXP/LOG/LOG10/LOG2/SQRT/CBRT/CEIL/FLOOR/ROUND/ABS``** -- Math operations have the same functionality as the C counterparts.

    * **``SIN MODE3,MODE2``** -- Perform the operation on the NUMBER operand and place the result in the last argument.  

    * **``POW MODE3,MODE3,MODE2``** -- Perform the pow() function and put the result in the lats argument.

* **``DUMP``** -- Dumps the complete state of the VM. Used for debugging.

## Assembler Layout
The assembler is very simple and free-form. It implements a simple symbol table but it does very little in the way of semantics checking. Note that directives and instructions are not case-sensitive.

* **Comments** -- C++ style line and block comments are supported.

* **Code Blocks** -- A code block is surrounded by **``{}``** characters. There is no restriction on nesting. The purpose of blocks syntactically is to let the assembler know to switch the storage mode. Instructions that appear outside of a code block create a syntax error, but anonymous code blocks are allowed.

* **Symbols** -- Assembler symbols follow the same general rules that C does. There is no difference between symbols that define data or that define labels in the code. All symbols must have a unique definition. Symbols must be defined before they are referenced.   
    * Here is a regular expression for a symbol: **``[a-zA-Z_][0-9a-zA-Z_]*``**.

* **Index Literals** -- An index literal is the same as an unsigned long in C. Integer arithmetic are supported.
    * Regex for index literal: **``(0[Xx][0-9a-fA-F]+)|([1-9][0-9]*)|0``**

* **Number Literals** -- Numbers in the VM are double precision floats. 
    * Regex for numbers: **``(([1-9][0-9]*)|0)?\.[0-9]*([eE][-+]?[0-9]+)?``**

* **``Include Directive``** -- The INCLUDE directive stops processing the current file and begins processing the file names by the directive as if it was the same file as the current one. When the included file runs out, processing is resumed with the original file. Included files may be nested up to 8 levels. Deeper nesting produces a compile error. If the included file is not accessible or if it has errors, then compilation cannot continue. 
    * Example: **``INCLUDE some/file/name.asm``**

* **``FUNC Directive``** -- The FUNC directive introduces a function definition. Code is automatically generated to push the parms on the stack and the stack pointer is set such that more PUSH instructions or local VAR definitions are stored on the stack properly. Functions cannot be nested. Code does not have to appear in a function definition. Code that appears outside of a function is concatenated and placed at the beginning of the stream of instructions. A RET instruction is required for the function to return.
    * Example syntax: **``FUNC some_name(parm1, parm2, parm3) { */ instructions */ }``**

* **``DATA Directive``** -- The DATA directive performs two different functions based on its context. If it appears outside of a code block then it defines a globally visible initialized storage. If it appears inside a code block, it is implemented as a PUSH instruction and allows the storage to be referenced by name. Local variables are name-scoped to the code block, so they do not need to be globally unique like they do elsewhere. The assembler tracks how many variables were allocated in the code block and uses ``POP INDEX`` to free the stack space when a ``}`` is encountered.
    * **``DATA some_name``** -- Defines a single 64 bit storage cell that is referenced by the name ``some_name``.
    * **``DATA another_name,16``** -- Defines 16 64 bit storage cells, referenced by name.
    * **``DATA good_name {0,0,0}``** -- Defines 3 64 bit storage cells with a value of zero.
    * **``DATA bad_name,16 {0}``** -- Defines 16 storage cells with the first one only set to zero.
    * **``DATA a_string {"this is a string"}``** Defines 3 storage cells with the string copied into it. There are 16 characters in the string, which takes up exactly 2 storage cells, but it must be zero terminated so another cell is allocated to hold the terminating zero and wasting 7 bytes of storage. There is no way to discover the size that was allocated at run time.



