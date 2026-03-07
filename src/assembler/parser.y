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
unsigned long data_counter = 0;
unsigned long code_counter = 0;
pointer_list_t* data_ptrs;

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
};

%token INCLUDE DATA EXTERN
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

%token <strg> QSTRG NAME
%token <ival> INTEGER
%token <uval> UNSIGNED
%token <fval> FLOAT

%type <ival> register index_constant index_expr

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
    : INCLUDE QSTRG {
            TRACE("include string: %s", raw_string($2));
            open_file(raw_string($2), ".asm");
        }
    ;

var_constant_list
    : var_constant {
            TRACE("create var_constant_list");

        }
    | var_constant_list ',' var_constant {
            TRACE("add to var_constant_list");
        }
    ;

index_constant
    : INTEGER {
            { TRACE("index_constant.INTEGER: %d", $1); }
        }
    | UNSIGNED {
            { TRACE("index_constant.UNSIGNED: 0x%04X", $1); }
        }
    ;

var_constant
    : index_constant {
            { TRACE("var_constant.index_constant"); }
        }
    | FLOAT {
            { TRACE("var_constant.FLOAT: %f", $1); }
        }
    | QSTRG {
            { TRACE("var_constant.QSTRG: %s", raw_string($1)); }
        }
    ;

var_def
    : DATA NAME {
            TRACE("var_def one slot: %s", raw_string($2));
            add_symbol($2, SYM_CODE, 1, data_counter++);
        }
    | DATA NAME '[' index_constant ']' {
            TRACE("var_def %lu slots: %s", $4, raw_string($2));
            add_symbol($2, SYM_CODE, $4, data_counter+=$4);
        }
    | DATA NAME '=' var_constant {
            TRACE("var_def with var_constant: %s", raw_string($2));
            add_symbol($2, SYM_CODE, 1, data_counter++);
            // save the initializer to the slot
        }
    | DATA NAME '=' '{' var_constant_list '}' {
            TRACE("var_def with var_constant_list: %s", raw_string($2));
            add_symbol($2, SYM_CODE, 1, data_counter++);
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
            $$ = 0;
        }
    | R02 {
            TRACE("register.R02");
            $$ = 1;
        }
    | R03 {
            TRACE("register.R02");
            $$ = 2;
        }
    | R04 {
            TRACE("register.R04");
            $$ = 3;
        }
    | R05 {
            TRACE("register.R05");
            $$ = 4;
        }
    | R06 {
            TRACE("register.R06");
            $$ = 5;
        }
    | R07 {
            TRACE("register.R07");
            $$ = 6;
        }
    | R08 {
            TRACE("register.R08");
            $$ = 7;
        }
    | R09 {
            TRACE("register.R09");
            $$ = 8;
        }
    | R10 {
            TRACE("register.R10");
            $$ = 9;
        }
    | R11 {
            TRACE("register.R11");
            $$ = 10;
        }
    | R12 {
            TRACE("register.R12");
            $$ = 11;
        }
    | R13 {
            TRACE("register.R13");
            $$ = 12;
        }
    | R14 {
            TRACE("register.R14");
            $$ = 13;
        }
    | R15 {
            TRACE("register.R15");
            $$ = 14;
        }
    | R16 {
            TRACE("register.R16");
            $$ = 15;
        }
    | R17 {
            TRACE("register.R17");
            $$ = 16;
        }
    | R18 {
            TRACE("register.R18");
            $$ = 17;
        }
    | R19 {
            TRACE("register.R19");
            $$ = 18;
        }
    | R20 {
            TRACE("register.R20");
            $$ = 19;
        }
    | R21 {
            TRACE("register.R21");
            $$ = 20;
        }
    | R22 {
            TRACE("register.R22");
            $$ = 21;
        }
    | R23 {
            TRACE("register.R23");
            $$ = 22;
        }
    | R24 {
            TRACE("register.R24");
            $$ = 23;
        }
    | R25 {
            TRACE("register.R25");
            $$ = 24;
        }
    | R26 {
            TRACE("register.R26");
            $$ = 25;
        }
    | R27 {
            TRACE("register.R27");
            $$ = 26;
        }
    | R28 {
            TRACE("register.R28");
            $$ = 27;
        }
    | R29 {
            TRACE("register.R29");
            $$ = 28;
        }
    | R30 {
            TRACE("register.R30");
            $$ = 29;
        }
    | R31 {
            TRACE("register.R31");
            $$ = 30;
        }
    | R32 {
            TRACE("register.R32");
            $$ = 31;
        }
    | SP {
            TRACE("register.SP");
            $$ = 32;
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
    | FLOAT {
            TRACE("mode3.FLOAT: %f", $1);
        }
    ;

arith_instr
    : ADD { TRACE("arith_instr.ADD"); }
    | ADDI { TRACE("arith_instr.ADDI"); }
    | ADDU { TRACE("arith_instr.ADDU"); }
    | ADDF { TRACE("arith_instr.ADDF"); }
    | SUB { TRACE("arith_instr.SUB"); }
    | SUBI { TRACE("arith_instr.SUBI"); }
    | SUBU { TRACE("arith_instr.SUBU"); }
    | SUBF { TRACE("arith_instr.SUBF"); }
    | MUL { TRACE("arith_instr.MUL"); }
    | MULI { TRACE("arith_instr.MULI"); }
    | MULU { TRACE("arith_instr.MULU"); }
    | MULF { TRACE("arith_instr.MULF"); }
    | DIV { TRACE("arith_instr.DIV"); }
    | DIVI { TRACE("arith_instr.DIVI"); }
    | DIVU { TRACE("arith_instr.DIVU"); }
    | DIVF { TRACE("arith_instr.DIVF"); }
    | MOD { TRACE("arith_instr.MOD"); }
    | MODI { TRACE("arith_instr.MODI"); }
    | MODU { TRACE("arith_instr.MODU"); }
    | MODF { TRACE("arith_instr.MODF"); }
    ;

ctrl_instr
    : CALL { TRACE("ctrl_instr.CALL"); }
    | CALLT { TRACE("ctrl_instr.CALLT"); }
    | CALLF { TRACE("ctrl_instr.CALLF"); }
    | JMP { TRACE("ctrl_instr.JMP"); }
    | JMPT { TRACE("ctrl_instr.JMPT"); }
    | JMPF { TRACE("ctrl_instr.JMPF"); }
    | RET { TRACE("ctrl_instr.RET"); }
    | RETT { TRACE("ctrl_instr.RETT"); }
    | RETF { TRACE("ctrl_instr.RETF"); }
    ;

comp_instr
    : LT { TRACE("comp_instr.LT"); }
    | GT { TRACE("comp_instr.GT"); }
    | LTE { TRACE("comp_instr.LTE"); }
    | GTE { TRACE("comp_instr.GTE"); }
    | EQ { TRACE("comp_instr.EQ"); }
    | NEQ { TRACE("comp_instr.NEQ"); }
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
    | EXTERN QSTRG { TRACE("EXTERN"); }
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

}
