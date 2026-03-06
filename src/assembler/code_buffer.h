

#ifndef _CODE_BUFFER_H_
#define _CODE_BUFFER_H_

typedef enum {
    // virtual machine instructions
    INSTR_PUSH = 0x00,
    INSTR_MOV = 0x01,
    INSTR_POP = 0x02,
    INSTR_CPY = 0x03,
    INSTR_ADD = 0x04,
    INSTR_SUB = 0x05,
    INSTR_MUL = 0x06,
    INSTR_DIV = 0x07,
    INSTR_MOD = 0x08,
    INSTR_CALL = 0x09,
    INSTR_JMP = 0x0A,
    INSTR_RET = 0x0B,
    INSTR_LT = 0x0C,
    INSTR_GT = 0x0D,
    INSTR_LTE = 0x0E,
    INSTR_GTE = 0x0F,
    INSTR_EQ = 0x10,
    INSTR_NEQ = 0x11,
    INSTR_STF = 0x12,
    INSTR_CTF = 0x13,
    INSTR_CALLT = 0x14,
    INSTR_CALLF = 0x15,
    INSTR_JMPT = 0x16,
    INSTR_JMPF = 0x17,
    INSTR_RETT = 0x18,
    INSTR_RETF = 0x19,
    INSTR_EXIT = 0x1A,
    INSTR_NOP = 0x1B,
    INSTR_EXTR = 0x1A,
} instruction_t;

typedef enum {
    REG_R01 = 0x00,
    REG_R02 = 0x01,
    REG_R03 = 0x02,
    REG_R04 = 0x03,
    REG_R05 = 0x04,
    REG_R06 = 0x05,
    REG_R07 = 0x06,
    REG_R08 = 0x07,
    REG_R09 = 0x08,
    REG_R10 = 0x09,
    REG_R11 = 0x0A,
    REG_R12 = 0x0C,
    REG_R13 = 0x0D,
    REG_R14 = 0x0E,
    REG_R15 = 0x0F,
    REG_R16 = 0x10,
    REG_R17 = 0x11,
    REG_R18 = 0x12,
    REG_R19 = 0x13,
    REG_R20 = 0x14,
    REG_R21 = 0x15,
    REG_R22 = 0x16,
    REG_R23 = 0x17,
    REG_R24 = 0x18,
    REG_R25 = 0x19,
    REG_R26 = 0x1A,
    REG_R27 = 0x1C,
    REG_R28 = 0x1D,
    REG_R29 = 0x1E,
    REG_R30 = 0x1F,
    REG_R31 = 0x20,
    REG_R32 = 0x21,
    REG_SP = 0x22,
} reg_t;

typedef struct {
    unsigned char* code;
    unsigned int len;
    unsigned int cap;
    unsigned int index;
} code_buffer_t;

void create_code_buffer(void);
void destroy_code_buffer(void);

unsigned int add_code_char(unsigned char val);
unsigned int add_code_short(unsigned short val);
unsigned int add_code_int(unsigned int val);
unsigned int add_code_long(unsigned long val);

unsigned char read_code_char(void);
unsigned short read_code_short(void);
unsigned int read_code_int(void);
unsigned long read_code_long(void);

unsigned char read_code_char_idx(unsigned int idx);
unsigned short read_code_short_idx(unsigned int idx);
unsigned int read_code_int_idx(unsigned int idx);
unsigned long read_code_long_idx(unsigned int idx);

#endif /* _CODE_BUFFER_H_ */
