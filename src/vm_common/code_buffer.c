
#include <stdio.h>
#include <string.h>
#include "common.h"

//#define _TESTING_
#include "code_buffer.h"

static code_buffer_t* code = NULL;

#define RESIZE(t, n)                                                       \
    if(code->len + sizeof(t) * (n) > code->cap) {                          \
        while(code->len + sizeof(t) * (n) > code->cap)                     \
            code->cap <<= 1;                                               \
        code->code = _REALLOC_ARRAY(code->code, unsigned char, code->cap); \
    }

void create_code_buffer(void) {

    if(code == NULL) {
        code = _ALLOC_TYPE(code_buffer_t);
        code->cap = 0x01 << 3;
        code->len = 0;
        code->code = _ALLOC_ARRAY(unsigned char, code->cap);
    }
}

void destroy_code_buffer(void) {

    if(code != NULL) {
        _FREE(code->code);
        _FREE(code);
    }
}

unsigned int add_code_char(unsigned char val) {

    ASSERT(code != NULL, "uninitialized code pointer");
    RESIZE(unsigned char, 1);

    unsigned char* tpt = &code->code[code->len];
    *tpt = val;
    code->len += sizeof(unsigned char);

    return code->len;
}

unsigned int add_code_short(unsigned short val) {

    ASSERT(code != NULL, "uninitialized code pointer");
    RESIZE(unsigned short, 1);

    unsigned short* tpt = (unsigned short*)&code->code[code->len];
    *tpt = val;
    code->len += sizeof(unsigned short);

    return code->len;
}

unsigned int add_code_int(unsigned int val) {

    ASSERT(code != NULL, "uninitialized code pointer");
    RESIZE(unsigned int, 1);

    unsigned int* tpt = (unsigned int*)&code->code[code->len];
    *tpt = val;
    code->len += sizeof(unsigned int);

    return code->len;
}

unsigned int add_code_long(unsigned long val) {

    ASSERT(code != NULL, "uninitialized code pointer");
    RESIZE(unsigned long, 1);

    unsigned long* tpt = (unsigned long*)&code->code[code->len];
    *tpt = val;
    code->len += sizeof(unsigned long);

    return code->len;
}

unsigned char read_code_char(void) {

    ASSERT(code != NULL, "uninitialized code pointer");
    unsigned char* tmp = (unsigned char*)&code->code[code->index];
    code->index += sizeof(unsigned char);
    return *tmp;
}

unsigned short read_code_short(void) {

    ASSERT(code != NULL, "uninitialized code pointer");
    unsigned short* tmp = (unsigned short*)&code->code[code->index];
    code->index += sizeof(unsigned short);
    return *tmp;
}

unsigned int read_code_int(void) {

    ASSERT(code != NULL, "uninitialized code pointer");
    unsigned int* tmp = (unsigned int*)&code->code[code->index];
    code->index += sizeof(unsigned int);
    return *tmp;
}

unsigned long read_code_long(void) {

    ASSERT(code != NULL, "uninitialized code pointer");
    unsigned long* tmp = (unsigned long*)&code->code[code->index];
    code->index += sizeof(unsigned long);
    return *tmp;
}

unsigned char read_code_char_idx(unsigned int idx) {

    ASSERT(code != NULL, "uninitialized code pointer");
    unsigned char* tmp = NULL;

    if(idx < code->len)
        tmp = (unsigned char*)&code->code[idx];
    else
        FATAL("invalid code index: %u, %u", idx, code->len);

    // this will not be reached if the idx is invalid
    return *tmp;
}

unsigned short read_code_short_idx(unsigned int idx) {

    ASSERT(code != NULL, "uninitialized code pointer");
    unsigned short* tmp = NULL;

    if(idx < code->len)
        tmp = (unsigned short*)&code->code[idx];
    else
        FATAL("invalid code index: %u, %u", idx, code->len);

    // this will not be reached if the idx is invalid
    return *tmp;
}

unsigned int read_code_int_idx(unsigned int idx) {

    ASSERT(code != NULL, "uninitialized code pointer");
    unsigned int* tmp = NULL;

    if(idx < code->len)
        tmp = (unsigned int*)&code->code[idx];
    else
        FATAL("invalid code index: %u, %u", idx, code->len);

    // this will not be reached if the idx is invalid
    return *tmp;
}

unsigned long read_code_long_idx(unsigned int idx) {

    ASSERT(code != NULL, "uninitialized code pointer");
    unsigned long* tmp = NULL;

    if(idx < code->len)
        tmp = (unsigned long*)&code->code[idx];
    else
        FATAL("invalid code index: %u, %u", idx, code->len);

    // this will not be reached if the idx is invalid
    return *tmp;
}

void reset_code_index(void) {

    ASSERT(code != NULL, "uninitialized code pointer");
    code->index = 0;
}

void set_code_index(unsigned int idx) {

    ASSERT(code != NULL, "uninitialized code pointer");
    if(idx < code->len)
        code->index = idx;
    else
        FATAL("invalid code index: %u, %u", idx, code->len);
}

#ifdef _TESTING_
/*
    Build string from source directory. Requires that make has created libcommon.a.
    clang -g -Wall -Wextra -Wpedantic -pedantic -I../common -L../../lib code_buffer.c -o t -lcommon -lgc -DUSE_ASSERTS
*/
#include <stdio.h>

int main(void) {

    create_code_buffer();

    printf("here1\n");
    add_code_short(0x123);
    printf("here2\n");
    printf("short: 0x%04X\n", read_code_short());
    printf("here3\n");

    add_code_short(0xAA0);
    printf("short: 0x%04X\n", read_code_short());

    add_code_long(0xDEADBEEF0000);
    printf("long: 0x%016lX\n", read_code_long());

    add_code_short(0xBB0);
    printf("short: 0x%04X\n", read_code_short());

    printf("short[0]: 0x%04X\n", read_code_short_idx(0));
    printf("short[1]: 0x%04X\n", read_code_short_idx(1));

    reset_code_index();
    printf("char: 0x%02X\n", read_code_char());
    printf("char: 0x%02X\n", read_code_char());
    printf("char: 0x%02X\n", read_code_char());
    printf("char: 0x%02X\n", read_code_char());
    printf("char: 0x%02X\n", read_code_char());

    printf("int: 0x%04X\n", read_code_int());
    printf("char: 0x%02X\n", read_code_char());
    printf("char: 0x%02X\n", read_code_char());

    destroy_code_buffer();

    return 0;
}

#endif

