%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "symbols.h"
#include "vm_common.h"
#include "file_io.h"
#include "common.h"

int yylex(void);
void yyerror(const char*);
extern int yylineno;
extern FILE *yyin, *yyout;

int errors = 0;
int data_index = 0;
int data_count = 0;
unsigned long code_counter = 0;
pointer_list_t* data_ptrs = NULL;

%}

// support the typedefs in the %union.
%code requires {
#include "symbols.h"
#include "pointer_list.h"
}

// this goes at the bottom of the generated header file.
%code provides {
const char* token_to_str(int);
void run_parser(void);
extern int errors;
}

%union {
    string_t* strg;
    int ival;
    unsigned int uval;
    float fval;
    data_item_t* data_item;
    symbol_t* symbol;
};

%token INCLUDE DATA EXTERN INT UINT FLOAT STRG
%token MOV PUSH POP CPY
%token LT GT LTE GTE EQ NEQ SETF CLRF
%token CALL JMP RET
%token CALLT JMPT RETT
%token CALLF JMPF RETF
%token ADD SUB MUL DIV MOD
%token ADDI SUBI MULI DIVI MODI
%token ADDU SUBU MULU DIVU MODU
%token ADDF SUBF MULF DIVF MODF
%token EXIT ABORT NOP

%token R01 R02 R03 R04 R05 R06 R07 R08 R09 R10 R11 R12 R13 R14 R15 R16
%token R17 R18 R19 R20 R21 R22 R23 R24 R25 R26 R27 R28 R29 R30 R31 R32
%token SP

%token <strg> STRG_LITERAL NAME
%token <ival> INT_LITERAL
%token <uval> UINT_LITERAL
%token <fval> FLOAT_LITERAL

%type <ival> register index_expr
%type <uval> arith_instr ctrl_instr comp_instr
%type <data_item> var_constant index_constant
%type <symbol> data_definition

%define parse.lac full
%define parse.error detailed
%locations
%verbose
    //%output "parser.c"
    //%defines

%left '+' '-'
%left '*' '/' '%'

%%

module
    : instruction_list {
            TRACE("module_item.instruction_list");

//             printf("trace verbosity: %d\n", peek_trace_verbosity());
//             printf("local verbosity: %d\n", local_verbosity);
        }
    ;

include
    : INCLUDE STRG_LITERAL {
            TRACE("include string: %s", raw_string($2));
            open_file(raw_string($2), ".asm");
        }
    ;

var_constant_list
    : var_constant {
            TRACE("create var_constant_list");
            if(data_ptrs == NULL)
                data_ptrs = create_ptr_list();
            append_ptr_list(data_ptrs, (void*)$1);
        }
    | var_constant_list ',' var_constant {
            TRACE("add to var_constant_list");
            append_ptr_list(data_ptrs, (void*)$3);
        }
    ;

index_constant
    : INT_LITERAL {
            TRACE("index_constant.INTEGER: %d", $1);
            $$ = create_ival_item(&$1);
        }
    | UINT_LITERAL {
            TRACE("index_constant.UNSIGNED: 0x%04X", $1);
            $$ = create_uval_item(&$1);
        }
    ;

var_constant
    : index_constant {
            TRACE("var_constant.index_constant");
            $$ = $1;
        }
    | FLOAT_LITERAL {
            TRACE("var_constant.FLOAT: %f", $1);
            $$ = create_fval_item(&$1);

        }
    | STRG_LITERAL {
            TRACE("var_constant.QSTRG: %s", raw_string($1));
            $$ = create_sval_t_item($1);
        }
    ;

data_definition
    : DATA NAME {
            TRACE("data_intro.-UINT- %s", raw_string($2));
        }
    | INT NAME {
            TRACE("data_intro.INT: %s", raw_string($2));
        }
    | UINT NAME {
            TRACE("data_intro.UINT: %s", raw_string($2));
        }
    | FLOAT NAME {
            TRACE("data_intro.FLOAT: %s", raw_string($2));
        }
    | STRG NAME {
            TRACE("data_intro.STRG: %s", raw_string($2));
        }
    ;

var_def
    : DATA NAME {
            // one uninitialized data element
            TRACE("var_def one slot: %s", raw_string($2));
            add_symbol($2, SYM_DATA, 1, append_data_buffer(create_ival_item(NULL)));
        }
    | DATA NAME '[' index_constant ']' {
            // several uninitialized data elements
            TRACE("var_def %lu slots: %s", $4, raw_string($2));
            data_index = append_data_buffer(0x00);
            for(int i = 1; i < $4; i++)
                append_data_buffer(0x00);
            add_symbol($2, SYM_DATA, $4, data_index);
        }
    | DATA NAME '=' var_constant {
            // one initialized data element
            TRACE("var_def with var_constant: %s", raw_string($2));
            add_symbol($2, SYM_DATA, 1, data_index);
            // save the initializer to the slot
        }
    | DATA NAME '=' '{' var_constant_list '}' {
            TRACE("var_def with var_constant_list: %s", raw_string($2));
            add_symbol($2, SYM_DATA, data_count, data_index);
            data_count = 0;
            // save the initializers to the list
        }
    ;

instruction_list
    : instruction {
            TRACE("create instruction_list");
        }
    | instruction_list instruction {
            TRACE("add to instruction_list");
        }
    ;

instruction
    : assembler_instruction {
            TRACE("instruction.assembler_instruction");
        }
    | var_def {
            TRACE("instruction.var_def");
        }
    | NAME ':' {
            TRACE("instruction.NAME: %s", raw_string($1));
        }
    | include {
            TRACE("module_item.include");
        }
    ;

register
    : R01 {
            TRACE("register.R01");
            $$ = REG_R01;
        }
    | R02 {
            TRACE("register.R02");
            $$ = REG_R02;
        }
    | R03 {
            TRACE("register.R02");
            $$ = REG_R03;
        }
    | R04 {
            TRACE("register.R04");
            $$ = REG_R04;
        }
    | R05 {
            TRACE("register.R05");
            $$ = REG_R05;
        }
    | R06 {
            TRACE("register.R06");
            $$ = REG_R06;
        }
    | R07 {
            TRACE("register.R07");
            $$ = REG_R07;
        }
    | R08 {
            TRACE("register.R08");
            $$ = REG_R08;
        }
    | R09 {
            TRACE("register.R09");
            $$ = REG_R09;
        }
    | R10 {
            TRACE("register.R10");
            $$ = REG_R10;
        }
    | R11 {
            TRACE("register.R11");
            $$ = REG_R11;
        }
    | R12 {
            TRACE("register.R12");
            $$ = REG_R12;
        }
    | R13 {
            TRACE("register.R13");
            $$ = REG_R13;
        }
    | R14 {
            TRACE("register.R14");
            $$ = REG_R14;
        }
    | R15 {
            TRACE("register.R15");
            $$ = REG_R15;
        }
    | R16 {
            TRACE("register.R16");
            $$ = REG_R16;
        }
    | R17 {
            TRACE("register.R17");
            $$ = REG_R17;
        }
    | R18 {
            TRACE("register.R18");
            $$ = REG_R18;
        }
    | R19 {
            TRACE("register.R19");
            $$ = REG_R19;
        }
    | R20 {
            TRACE("register.R20");
            $$ = REG_R20;
        }
    | R21 {
            TRACE("register.R21");
            $$ = REG_R21;
        }
    | R22 {
            TRACE("register.R22");
            $$ = REG_R22;
        }
    | R23 {
            TRACE("register.R23");
            $$ = REG_R23;
        }
    | R24 {
            TRACE("register.R24");
            $$ = REG_R24;
        }
    | R25 {
            TRACE("register.R25");
            $$ = REG_R25;
        }
    | R26 {
            TRACE("register.R26");
            $$ = REG_R26;
        }
    | R27 {
            TRACE("register.R27");
            $$ = REG_R27;
        }
    | R28 {
            TRACE("register.R28");
            $$ = REG_R28;
        }
    | R29 {
            TRACE("register.R29");
            $$ = REG_R29;
        }
    | R30 {
            TRACE("register.R30");
            $$ = REG_R30;
        }
    | R31 {
            TRACE("register.R31");
            $$ = REG_R31;
        }
    | R32 {
            TRACE("register.R32");
            $$ = REG_R32;
        }
    | SP {
            TRACE("register.SP");
            $$ = REG_SP;
        }
    ;

index_expr
    : index_constant {
            $$ = $1;
            TRACE("index_expr.index_constant: %d", $$);
        }
    | index_expr '+' index_expr {
            $$ = $1 + $3;
            TRACE("index_expr.+ %d", $$);
        }
    | index_expr '-' index_expr {
            $$ = $1 - $3;
            TRACE("index_expr.- %d", $$);
        }
    | index_expr '*' index_expr {
            $$ = $1 * $3;
            TRACE("index_expr.* %d", $$);
        }
    | index_expr '/' index_expr {
            if($1 == 0)
                yyerror("divide by zero in index expression");
            else
                $$ = $1 / $3;
            TRACE("index_expr./ %d", $$);
        }
    | index_expr '%' index_expr {
            if($1 == 0)
                yyerror("modulo by zero in index expression");
            else
                $$ = $1 % $3;
            TRACE("index_expr.%% %d", $$);
        }
    | '(' index_expr ')' {
            $$ = $2;
            TRACE("(index_expr): %d", $$);
        }
    ;

index
    : '[' index_expr ']' {
            TRACE("index: %d", $2);
        }
    | '[' ']' {
            TRACE("blank index");
        }
    ;

mode1
    : register {
            TRACE("mode1.register");
        }
    | register index {
            TRACE("mode1.register_index");
        }
    | NAME {
            TRACE("mode1.NAME: %s", raw_string($1));
        }
    ;

mode2
    : mode1 {
            TRACE("mode2.mode1");
        }
    | index_constant {
            TRACE("mode2.index_constant: 0x%04X", (unsigned)$1);
        }
    ;

mode3
    : mode2 {
            TRACE("mode3.mode2");
        }
    | FLOAT_LITERAL {
            TRACE("mode3.FLOAT: %f", $1);
        }
    ;

arith_instr
    : ADD {
            TRACE("arith_instr.ADD");
            $$ = INSTR_ADD;
        }
    | ADDI {
            TRACE("arith_instr.ADDI");
            $$ = INSTR_ADDI;
        }
    | ADDU {
            TRACE("arith_instr.ADDU");
            $$ = INSTR_ADDU;
        }
    | ADDF {
            TRACE("arith_instr.ADDF");
            $$ = INSTR_ADDF;
        }
    | SUB {
            TRACE("arith_instr.SUB");
            $$ = INSTR_SUB;
        }
    | SUBI {
            TRACE("arith_instr.SUBI");
            $$ = INSTR_SUBI;
        }
    | SUBU {
            TRACE("arith_instr.SUBU");
            $$ = INSTR_SUBU;
        }
    | SUBF {
            TRACE("arith_instr.SUBF");
            $$ = INSTR_SUBF;
        }
    | MUL {
            TRACE("arith_instr.MUL");
            $$ = INSTR_MUL;
        }
    | MULI {
            TRACE("arith_instr.MULI");
            $$ = INSTR_MULI;
        }
    | MULU {
            TRACE("arith_instr.MULU");
            $$ = INSTR_MULU;
        }
    | MULF {
            TRACE("arith_instr.MULF");
            $$ = INSTR_MULF;
        }
    | DIV {
            TRACE("arith_instr.DIV");
            $$ = INSTR_DIV;
        }
    | DIVI {
            TRACE("arith_instr.DIVI");
            $$ = INSTR_DIVI;
        }
    | DIVU {
            TRACE("arith_instr.DIVU");
            $$ = INSTR_DIVU;
        }
    | DIVF {
            TRACE("arith_instr.DIVF");
            $$ = INSTR_DIVF;
        }
    | MOD {
            TRACE("arith_instr.MOD");
            $$ = INSTR_MOD;
        }
    | MODI {
            TRACE("arith_instr.MODI");
            $$ = INSTR_MODI;
        }
    | MODU {
            TRACE("arith_instr.MODU");
            $$ = INSTR_MODU;
        }
    | MODF {
            TRACE("arith_instr.MODF");
            $$ = INSTR_MODF;
        }
    ;

ctrl_instr
    : CALL {
            TRACE("ctrl_instr.CALL");
            $$ = INSTR_CALL;
        }
    | CALLT {
            TRACE("ctrl_instr.CALLT");
            $$ = INSTR_CALLT;
        }
    | CALLF {
            TRACE("ctrl_instr.CALLF");
            $$ = INSTR_CALLF;
        }
    | JMP {
            TRACE("ctrl_instr.JMP");
            $$ = INSTR_JMP;
        }
    | JMPT {
            TRACE("ctrl_instr.JMPT");
            $$ = INSTR_JMPT;
        }
    | JMPF {
            TRACE("ctrl_instr.JMPF");
            $$ = INSTR_JMPF;
        }
    | RET {
            TRACE("ctrl_instr.RET");
            $$ = INSTR_RET;
        }
    | RETT {
            TRACE("ctrl_instr.RETT");
            $$ = INSTR_RETT;
        }
    | RETF {
            TRACE("ctrl_instr.RETF");
            $$ = INSTR_RETF;
        }
    ;

comp_instr
    : LT {
            TRACE("comp_instr.LT");
            $$ = INSTR_LT;
        }
    | GT {
            TRACE("comp_instr.GT");
            $$ = INSTR_GT;
        }
    | LTE {
            TRACE("comp_instr.LTE");
            $$ = INSTR_LTE;
        }
    | GTE {
            TRACE("comp_instr.GTE");
            $$ = INSTR_GTE;
        }
    | EQ {
            TRACE("comp_instr.EQ");
            $$ = INSTR_EQ;
        }
    | NEQ {
            TRACE("comp_instr.NEQ");
            $$ = INSTR_NEQ;
        }
    ;

assembler_instruction
    : MOV mode1 ',' mode3  { TRACE("MOV"); }
    | PUSH mode3 { TRACE("PUSH"); }
    | POP mode1 { TRACE("POP"); }
    | CPY mode1 ',' register ',' index_constant { TRACE("CPY"); }
    | arith_instr mode1 ',' register ',' register { TRACE("arith_instr mode1"); }
    | ctrl_instr mode1 { TRACE("ctrl_instr mode1 "); }
    | comp_instr mode2 ',' mode2 { TRACE("comp_instr mode2"); }
    | SETF { TRACE("STF"); }
    | CLRF { TRACE("CTF"); }
    | EXIT { TRACE("EXIT"); }
    | EXIT index_constant { TRACE("EXIT INDEX"); }
    | ABORT { TRACE("ABORT"); }
    | NOP { TRACE("NOP"); }
    | EXTERN STRG_LITERAL { TRACE("EXTERN"); }
    ;

%%

extern char* yytext;
void yyerror(const char* s) {

    if(yytext[0] != '\0')
        fprintf(stderr, "%d:%d:%s: %s: %s\n", get_line_no(), get_col_no(), get_file_name(), s, yytext);
    else
        fprintf(stderr, "%d:%d:%s: %s\n", get_line_no(), get_col_no(), get_file_name(), s);
    errors++;
}

const char* token_to_str(int tok) {

    return yysymbol_name(YYTRANSLATE(tok));
}

void run_parser(void) {

    if(in_cmd_list("dump", "parser"))
        LOCAL_VERBOSITY(0);
    else
        LOCAL_VERBOSITY(19);

    TRACE_HEADER;

    create_code_buffer();
    create_data_buffer();

    const char* fname = raw_string(get_cmd_opt("files"));
    open_file(fname, ".asm");

    yyparse();

    dump_sym_table();
    dump_data_buffer();

}
