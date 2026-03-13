

#ifndef _CODE_BUFFER_H_
#define _CODE_BUFFER_H_

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

void reset_code_index(void);
void set_code_index(unsigned int);

#endif /* _CODE_BUFFER_H_ */
