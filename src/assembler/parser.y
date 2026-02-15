%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "tokens.h"
#include "ast.h"
#include "file_io.h"
#include "common.h"

int yylex(void);
void yyerror(const char*);
extern int yylineno;
extern FILE *yyin, *yyout;

int errors = 0;

%}

// support the typedefs in the %union.
%code requires {
#include "ast.h"
#include "tokens.h"
#include "pointer_list.h"
}

// this goes at the bottom of the generated header file.
%code provides {
const char* token_to_str(int);
void init_parser(void);
extern int errors;
}

%union {
    string_t* strg;
    unsigned long ival;
    double fval;
};

%token INCLUDE FUNC DATA
%token PUSH MOV POP CPY ADD SUB MUL DIV MOD CALL JMP RET LT GT LTE GTE
%token EQ NEQ STF CTF CALLT CALLF JMPT JMPF RETT RETF EXIT NOP
%token PRI PRN PRS PRF INP OPENR OPENW CLOSE READ WRITE ALLOC FREE DUMP
%token SIN COS TAN ASIN ATAN ACOS SINH COSH TANH EXP
%token LOG LOG10 LOG2 SQRT CBRT CEIL FLOOR ROUND ABS POW
%token R01 R02 R03 R04 R05 R06 R07 R08 R09 R10 R11 R12 R13 R14 R15 R16
%token R17 R18 R19 R20 R21 R22 R23 R24 R25 R26 R27 R28 R29 R30 R31 R32

%token <strg> QSTRG NAME
%token <ival> INDEX
%token <fval> NUMBER

%define parse.lac full
%define parse.error detailed
%locations
%verbose
    //%output "parser.c"
    //%defines

%%

module
    : module_item {}
    | module module_item {}
    ;

module_item
    : include
    | function_def
    | var_def
    | code_block
    ;

include
    : INCLUDE QSTRG {
            TRACE("include string: %s", raw_string($2));
            open_file(raw_string($2), ".asm");
        }
    ;

var_def
    : DATA NAME
    ;

code_block
    : '{' code_block_item_list '}'
    ;

param_list_item
    : NAME
    | INDEX
    | NUMBER
    ;

param_list
    : param_list_item
    | param_list ',' param_list_item
    ;

func_params
    : '(' ')'
    | '(' param_list ')'
    ;

function_def
    : FUNC NAME func_params code_block
    ;

code_block_item_list
    : code_block_item
    | code_block_item_list code_block_item
    ;

code_block_item
    : var_def
    | code_block
    | instruction
    ;

instruction
    : assembler_instruction
    | assembler_function
    ;

register
    : R01   {}
    | R02   {}
    | R03   {}
    | R04   {}
    | R05   {}
    | R06   {}
    | R07   {}
    | R08   {}
    | R09   {}
    | R10   {}
    | R11   {}
    | R12   {}
    | R13   {}
    | R14   {}
    | R15   {}
    | R16   {}
    | R17   {}
    | R18   {}
    | R19   {}
    | R20   {}
    | R21   {}
    | R22   {}
    | R23   {}
    | R24   {}
    | R25   {}
    | R26   {}
    | R27   {}
    | R28   {}
    | R29   {}
    | R30   {}
    | R31   {}
    | R32   {}
    ;

index_item
    : INDEX
    | register
    ;

index
    : '[' index_item ']'
    | '[' index_item '+' index_item ']'
    | '[' index_item '-' index_item ']'
    ;

mode1
    : register {}
    | register index
    ;

mode2
    : mode1 {}
    | NUMBER
    | INDEX
    ;

mode3
    : mode1 {}
    | NUMBER
    ;

mode4
    : mode1 {}
    | INDEX
    ;

assembler_instruction
    : MOV mode2 ',' mode1  {}
    | PUSH mode2 {}
    | POP INDEX {}
    | CPY mode2 ',' mode1 ',' INDEX {}
    | ADD mode2 ',' mode2 ',' mode1 {}
    | SUB mode2 ',' mode2 ',' mode1 {}
    | MUL mode2 ',' mode2 ',' mode1 {}
    | DIV mode2 ',' mode2 ',' mode1 {}
    | MOD mode2 ',' mode2 ',' mode1 {}
    | CALL mode4 {}
    | CALLT mode4 {}
    | CALLF mode4 {}
    | JMP mode4 {}
    | JMPT mode4 {}
    | JMPF mode4 {}
    | RET {}
    | RET INDEX {}
    | RETT  {}
    | RETT INDEX {}
    | RETF  {}
    | RETF INDEX {}
    | LT mode2 ',' mode2 {}
    | GT mode2 ',' mode2 {}
    | LTE mode2 ',' mode2 {}
    | GTE mode2 ',' mode2 {}
    | EQ mode2 ',' mode2 {}
    | NEQ mode2 ',' mode2 {}
    | STF {}
    | CTF {}
    | EXIT {}
    | EXIT INDEX {}
    | NOP {}
    ;

assembler_function
    : PRI register {}
    | PRN register {}
    | PRS register {}
    | PRF register ',' register ',' INDEX {}
    | INP register {}
    | OPENR register ',' register {}
    | OPENW register ',' register {}
    | CLOSE register {}
    | READ register ',' register ',' INDEX {}
    | WRITE register ',' register ',' INDEX {}
    | ALLOC register ',' INDEX {}
    | FREE register {}
    | DUMP {}
    | SIN mode3 ',' mode1 {}
    | COS mode3 ',' mode1 {}
    | TAN mode3 ',' mode1 {}
    | ASIN mode3 ',' mode1 {}
    | ACOS mode3 ',' mode1 {}
    | ATAN mode3 ',' mode1 {}
    | SINH mode3 ',' mode1 {}
    | COSH mode3 ',' mode1 {}
    | TANH mode3 ',' mode1 {}
    | EXP mode3 ',' mode1 {}
    | LOG mode3 ',' mode1 {}
    | LOG10 mode3 ',' mode1 {}
    | LOG2 mode3 ',' mode1 {}
    | SQRT mode3 ',' mode1 {}
    | CBRT mode3 ',' mode1 {}
    | CEIL mode3 ',' mode1 {}
    | FLOOR mode3 ',' mode1 {}
    | ROUND mode3 ',' mode1 {}
    | ABS mode3 ',' mode1 {}
    | POW mode3 ',' mode3 ',' mode1 {}
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

void init_parser(void) {

    if(in_cmd_list("dump", "parser"))
        LOCAL_VERBOSITY(0);
    else
        LOCAL_VERBOSITY(19);

    TRACE_HEADER;

    /*
    const char* fname = raw_string(get_cmd_opt("files"));
    if(fname != NULL) {
        yyin = fopen(fname, "r");
        if(yyin == NULL) {
            fprintf(stderr, "cannot open input file \"%s\": %s\n", fname, strerror(errno));
            cmdline_help();
        }
    }
    else
        FATAL("internal error in %s: command line failed", __func__);
    */
    const char* fname = raw_string(get_cmd_opt("files"));
    open_file(fname, ".asm");
}
