
#include <stdio.h>
#include "common.h"
#include "data_buffer.h"

static data_buffer_t* data = NULL;

void create_data_buffer(void) {

    if(data != NULL) {
        data = _ALLOC_TYPE(data_buffer_t);
        data->cap = 0x01 << 3;
        data->len = 0;
        data->data = _ALLOC_ARRAY(unsigned int, data->cap);
    }
}

void destroy_data_buffer(void) {

    if(data != NULL) {
        _FREE(data->data);
        _FREE(data);
    }
}

unsigned int append_data_buffer(unsigned int val) {

    if(data->len + 1 > data->cap) {
        data->cap <<= 1;
        data->data = _REALLOC_ARRAY(data->data, unsigned int, data->cap);
    }

    data->data[data->len] = val;
    data->len++;

    return data->len;
}

unsigned int get_data_buffer(unsigned int index) {

    if(index < data->len)
        return data->data[index];
    else
        FATAL("invalid data buffer index: %u, %u", index, data->len);
}
