
#include "symbols.h"

hash_table_t* sym_table = NULL;

void create_symbol_table(void) {

    if(sym_table == NULL)
        sym_table = create_hashtable();
}

void add_symbol(string_t* name, int type, int length, unsigned int index) {

    if(sym_table == NULL)
        sym_table = create_hashtable();

    symbol_t* sym = _ALLOC_TYPE(symbol_t);
    sym->name = copy_string(name);
    sym->type = type;
    sym->length = length;
    sym->index = index;

    insert_hashtable(sym_table, raw_string(name), (void*)sym);
}

symbol_t* get_symbol(string_t* name) {

    symbol_t* sym = NULL;

    find_hashtable(sym_table, raw_string(name), (void*)&sym);

    return sym;
}
