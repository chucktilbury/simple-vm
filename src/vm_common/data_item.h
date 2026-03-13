#ifndef _DATA_ITEM_H_
#define _DATA_ITEM_H_

#include <stdio.h>
#include "common.h"

typedef enum {
    DTYPE_INTEGER,
    DTYPE_UNSIGNED,
    DTYPE_FLOAT,
    DTYPE_STRING,
} data_type_t;

typedef struct {
    data_type_t type;
    union {
        string_t* sval;
        int ival;
        unsigned uval;
        float fval;
    } data __attribute__((packed));
} data_item_t;

data_item_t* create_sval_item(char* val);
data_item_t* create_sval_t_item(string_t* val);
data_item_t* create_ival_item(int* val);
data_item_t* create_uval_item(unsigned* val);
data_item_t* create_fval_item(float* val);

void destroy_data_item(data_item_t*);

void save_data_item(FILE* fptr, data_item_t* data);
data_item_t* load_data_item(FILE* fptr);

#define data_item_type(d) ((d)->type)
#define data_sval(d) ((d)->data.sval)
#define raw_data_sval(d) raw_string(((d)->data.sval))
#define data_ival(d) ((d)->data.ival)
#define data_uval(d) ((d)->data.uval)
#define data_fval(d) ((d)->data.fval)

void dump_data_item(data_item_t* ptr);

#endif /* _DATA_ITEM_H_ */
