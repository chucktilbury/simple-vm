
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

static void dump_symbol(symbol_t* sym) {

    printf("name %s: type %d: length %d: index %u\n", raw_string(sym->name), sym->type, sym->length, sym->index);
}

void dump_sym_table(void) {

    int count = 1;

    printf("-----------symbol table----------\n");
    printf("cap = %d\n", sym_table->cap);
    printf("count = %d\n", sym_table->count);
    for(int i = 0; i < sym_table->cap; i++) {
        if(sym_table->table[i] != NULL) {
            if(sym_table->table[i]->key != NULL) {
                printf("%3d. slot=%d key=%s\n", count, i, sym_table->table[i]->key);
                dump_symbol(sym_table->table[i]->data);
                count++;
            }
        }
    }
}

