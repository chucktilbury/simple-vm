

#ifndef _DATA_BUFFER_H_
#define _DATA_BUFFER_H_

#include "data_item.h"

void create_data_buffer(void);
void destroy_data_buffer(void);
int append_data_buffer(data_item_t*);
int add_unsigned_data(unsigned);
int add_int_data(int);
int add_float_data(float);
int add_string_data(char*);
int get_int_data(int index);
unsigned int get_unsigned_data(int index);
float get_float_data(int index);
string_t* get_string_data(int index);
data_item_t* get_data_item(int index);
void dump_data_buffer(void);

#endif /* _DATA_BUFFER_H_ */
