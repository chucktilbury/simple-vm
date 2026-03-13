
#include <string.h>
#include "common.h"

#include "data_buffer.h"

#define TO_DATA(t, v) (*((unsigned int*)((t*)(&(v)))))

static pointer_list_t* data = NULL;

void create_data_buffer(void) {

    if(data == NULL)
        data = create_ptr_list();
}

void destroy_data_buffer(void) {

    if(data != NULL) {
        int post = 0;
        for(void* ptr = iterate_ptr_list(data, &post); ptr != NULL; ptr = iterate_ptr_list(data, &post))
            destroy_data_item((data_item_t*)ptr);
        destroy_ptr_list(data);
    }
}

int append_data_buffer(data_item_t* val) {

    if(val != NULL)
        append_ptr_list(data, create_uval_item(val));
    else
        append_ptr_list(data, create_uval_item(NULL));
    return len_ptr_list(data)-1;
}

int add_unsigned_data(unsigned val) {

    ASSERT(data != NULL, "uninitialized data pointer");
    return append_data_buffer(create_uval_item(&val));
}

int add_int_data(int val) {

    ASSERT(data != NULL, "uninitialized data pointer");
    return append_data_buffer(create_ival_item(&val));
}

int add_float_data(float val) {

    ASSERT(data != NULL, "uninitialized data pointer");
    return append_data_buffer(create_fval_item(&val));
}


int add_string_data(char* str) {

    ASSERT(data != NULL, "uninitialized data pointer");
    return append_data_buffer(create_sval_item(str));
}

data_item_t* get_data_item(int index) {

    ASSERT(data != NULL, "uninitialized data pointer");
    return index_ptr_list(data, index);
}

int get_int_data(int index) {

    ASSERT(data != NULL, "uninitialized data pointer");
    return get_data_item(index)->data.ival;
}

unsigned int get_unsigned_data(int index) {

    ASSERT(data != NULL, "uninitialized data pointer");
    return get_data_item(index)->data.uval;
}

float get_float_data(int index) {

    ASSERT(data != NULL, "uninitialized data pointer");
    return get_data_item(index)->data.fval;
}

string_t* get_string_data(int index) {

    ASSERT(data != NULL, "uninitialized data pointer");
    return get_data_item(index)->data.sval;
}

void dump_data_buffer(void) {

    int post = 0;
    data_item_t* ptr;
    printf("----------data buffer---------\n");
    for(ptr = iterate_ptr_list(data, &post); ptr != NULL; ptr = iterate_ptr_list(data, &post))
        dump_data_item(ptr);
}

