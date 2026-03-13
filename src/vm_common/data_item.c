#include "data_item.h"

data_item_t* create_sval_item(char* val) {

    data_item_t* di = _ALLOC_TYPE(data_item_t);
    di->type = DTYPE_STRING;
    di->data.sval = create_string(val);

    return di;
}

data_item_t* create_sval_t_item(string_t* val) {

    data_item_t* di = _ALLOC_TYPE(data_item_t);
    di->type = DTYPE_STRING;
    di->data.sval = copy_string(val);

    return di;
}

data_item_t* create_ival_item(int* val) {

    data_item_t* di = _ALLOC_TYPE(data_item_t);
    di->type = DTYPE_INTEGER;
    if(val != NULL)
        di->data.ival = *val;

    return di;
}

data_item_t* create_uval_item(unsigned* val) {

    data_item_t* di = _ALLOC_TYPE(data_item_t);
    di->type = DTYPE_UNSIGNED;
    if(val != NULL)
        di->data.uval = *val;

    return di;
}

data_item_t* create_fval_item(float* val) {

    data_item_t* di = _ALLOC_TYPE(data_item_t);
    di->type = DTYPE_FLOAT;
    if(val != NULL)
        di->data.uval = *val;

    return di;
}

void destroy_data_item(data_item_t* di) {

    ASSERT(di != NULL, "NULL data item");
    if(di->type == DTYPE_STRING)
        destroy_string(di->data.sval);
    _FREE(di);
}

void save_data_item(FILE* fptr, data_item_t* data)  {

    ASSERT(data != NULL, "NULL data item");
    fwrite(&data->type, sizeof(data_type_t), 1, fptr);
    switch(data->type) {
        case DTYPE_INTEGER:
            fwrite(&data->data.ival, sizeof(int), 1, fptr);
            break;
        case DTYPE_UNSIGNED:
            fwrite(&data->data.uval, sizeof(unsigned), 1, fptr);
            break;
        case DTYPE_FLOAT:
            fwrite(&data->data.fval, sizeof(float), 1, fptr);
            break;
        case DTYPE_STRING:
            fwrite(&data->data.sval->len, sizeof(int), 1, fptr);
            fwrite(&data->data.sval->buffer, sizeof(char), data->data.sval->len, fptr);
            break;
        default:
            FATAL("Attempt to write unknown data type: %d", data->type);
    }
}

data_item_t* load_data_item(FILE* fptr)  {

    data_item_t* di = _ALLOC_TYPE(data_item_t);
    fread(&di->type, sizeof(data_type_t), 1, fptr);
    switch(di->type) {
        case DTYPE_INTEGER:
            fread(&di->data.ival, sizeof(int), 1, fptr);
            break;
        case DTYPE_UNSIGNED:
            fread(&di->data.uval, sizeof(unsigned), 1, fptr);
            break;
        case DTYPE_FLOAT:
            fread(&di->data.fval, sizeof(float), 1, fptr);
            break;
        case DTYPE_STRING: {
                int len;
                fread(&len, sizeof(int), 1, fptr);
                char* str = _ALLOC_ARRAY(char, len+1);
                fread(str, sizeof(char), len, fptr);
                di->data.sval = create_string(str);
                _FREE(str);
            }
            break;
        default:
            FATAL("Attempt to read unknown data type: %d", di->type);
    }

    return di;
}

#define DATA_TYPE_TO_STR(t) ( \
    ((t) == DTYPE_INTEGER)? "DTYPE_INTEGER" : \
    ((t) == DTYPE_UNSIGNED)? "DTYPE_UNSIGNED" : \
    ((t) == DTYPE_FLOAT)? "DTYPE_FLOAT" : \
    ((t) == DTYPE_STRING)? "DTYPE_STRING" : "UNKNOWN_DATA_TYPE")

void dump_data_item(data_item_t* ptr) {

    ASSERT(di != NULL, "NULL data item");
    printf("%s: ", DATA_TYPE_TO_STR(ptr->type));
    switch(ptr->type) {
        case DTYPE_INTEGER: printf("%d", ptr->data.ival); break;
        case DTYPE_UNSIGNED: printf("%u", ptr->data.uval); break;
        case DTYPE_FLOAT: printf("%f", ptr->data.fval); break;
        case DTYPE_STRING: printf("%s", raw_string(ptr->data.sval)); break;
        default:
            FATAL("\nAttempt to dump unknown data type: %d", ptr->type);
    }

    fputc('\n', stdout);
}