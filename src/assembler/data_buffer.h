

#ifndef _DATA_BUFFER_H_
#define _DATA_BUFFER_H_

typedef struct {
    unsigned int* data;
    unsigned int len;
    unsigned int cap;
} data_buffer_t;

void create_data_buffer(void);
void destroy_data_buffer(void);
unsigned int append_data_buffer(unsigned int data);
unsigned int get_data_buffer(unsigned int index);

#endif /* _DATA_BUFFER_H_ */
