%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "symbols.h"
#include "code_buffer.h"
#include "data_buffer.h"
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
    unsigned long ival;
    double fval;
};

%token INCLUDE DATA EXTRN
%token PUSH MOV POP CPY ADD SUB MUL DIV MOD CALL JMP RET LT GT LTE GTE
%token EQ NEQ STF CTF CALLT CALLF JMPT JMPF RETT RETF EXIT NOP

%token R01 R02 R03 R04 R05 R06 R07 R08 R09 R10 R11 R12 R13 R14 R15 R16
%token R17 R18 R19 R20 R21 R22 R23 R24 R25 R26 R27 R28 R29 R30 R31 R32
%token SP

%token <strg> QSTRG NAME
%token <ival> INDEX
%token <fval> NUMBER

%type <ival> register

%define parse.lac full
%define parse.error detailed
%locations
%verbose
    //%output "parser.c"
    //%defines

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
            TRACE("CREATE var_constant_list");

        }
    | var_constant_list ',' var_constant {
            TRACE("ADD var_constant_list");
        }
    ;

var_constant
    : INDEX {
        }
    | NUMBER {
        }
    | QSTRG {
        }
    ;

var_def
    : NAME {
            TRACE("var_def one slot: %s", raw_string($1));
            add_symbol($1, SYM_CODE, 1, data_counter++);
        }
    | NAME '[' INDEX ']' {
            TRACE("var_def %lu slots: %s", $3, raw_string($1));
            add_symbol($1, SYM_CODE, $3, data_counter+=$3);
        }
    | NAME '=' var_constant {
            TRACE("var_def with var_constant: %s", raw_string($1));
            add_symbol($1, SYM_CODE, 1, data_counter++);
            // save the initializer to the slot
        }
    | NAME '=' '{' var_constant_list '}' {
            TRACE("var_def with var_constant_list: %s", raw_string($1));
            //add_symbol($1, SYM_CODE, 1, data_counter++);
            // save the initializers to the list
        }
    ;

instruction_list
    : instruction {
            TRACE("CREATE instruction_list");
        }
    | instruction_list instruction {
            TRACE("ADD instruction_list");
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

index_item
    : INDEX {
            TRACE("index_item.INDEX: %lu", $1);
        }
    | register {
            TRACE("index_item.register: %lu", $1);
        }
    ;

index
    : '[' index_item ']' {
            TRACE("index");
        }
    | '[' index_item '+' index_item ']' {
            TRACE("index add");
        }
    | '[' index_item '-' index_item ']' {
            TRACE("index subtract");
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
    | NUMBER {
            TRACE("mode2.NUMBER: %f", $1);
        }
    | INDEX {
            TRACE("mode2.INDEX: %lu", $1);
        }
    ;

mode3
    : mode1 {
            TRACE("mode3.mode1");
        }
    | NUMBER {
            TRACE("mode3.NUMBER: %f", $1);
        }
    ;

mode4
    : mode1 {
            TRACE("mode4.mode1");
        }
    | INDEX {
            TRACE("mode4.INDEX: %f", $1);
        }
    ;

assembler_instruction
    : MOV mode2 ',' mode1  { TRACE("MOV"); }
    | PUSH mode2 { TRACE("PUSH"); }
    | POP INDEX { TRACE("POP"); }
    | CPY mode2 ',' mode1 ',' INDEX { TRACE("CPY"); }
    | ADD mode2 ',' mode2 ',' mode1 { TRACE("ADD"); }
    | SUB mode2 ',' mode2 ',' mode1 { TRACE("SUB"); }
    | MUL mode2 ',' mode2 ',' mode1 { TRACE("MUL"); }
    | DIV mode2 ',' mode2 ',' mode1 { TRACE("DIV"); }
    | MOD mode2 ',' mode2 ',' mode1 { TRACE("MOD"); }
    | CALL mode4 { TRACE("CALL"); }
    | CALLT mode4 { TRACE("CALLT"); }
    | CALLF mode4 { TRACE("CALLF"); }
    | JMP mode4 { TRACE("JMP"); }
    | JMPT mode4 { TRACE("JMPT"); }
    | JMPF mode4 { TRACE("JMPF"); }
    | RET { TRACE("RET"); }
    | RET INDEX { TRACE("RET INDEX"); }
    | RETT  { TRACE("RETT "); }
    | RETT INDEX { TRACE("RETT INDEX"); }
    | RETF  { TRACE("RETF "); }
    | RETF INDEX { TRACE("RETF INDEX"); }
    | LT mode2 ',' mode2 { TRACE("LT"); }
    | GT mode2 ',' mode2 { TRACE("GT"); }
    | LTE mode2 ',' mode2 { TRACE("LTE"); }
    | GTE mode2 ',' mode2 { TRACE("GTE"); }
    | EQ mode2 ',' mode2 { TRACE("EQ"); }
    | NEQ mode2 ',' mode2 { TRACE("NEQ"); }
    | STF { TRACE("STF"); }
    | CTF { TRACE("CTF"); }
    | EXIT { TRACE("EXIT"); }
    | EXIT INDEX { TRACE("EXIT INDEX"); }
    | NOP { TRACE("NOP"); }
    | EXTR { TRACE("EXTR"); }
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
