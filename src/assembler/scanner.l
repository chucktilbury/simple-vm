%{

#include "parser.h"
#include "file_io.h"
#include "common.h"

int depth;
string_t* strbuf = NULL;
void yyerror(const char* s);
int yycolno = 1;
int prev_lineno;

#define MAX_INCL 16

#define YY_USER_ACTION update_numbers();

%}

%option yylineno
%option noinput
%option nounput
%option noyywrap
    // for cmake...
    //%option header-file="scanner.h"
    //%option outfile="scanner.c"

%x LCOMMENT BCOMMENT DQUOTE SQUOTE

%%

"include"   { return INCLUDE; }
"data"      { return DATA; }
"extern"    { return EXTERN; }
"mov"|"move" { return MOV; }
"push"      { return PUSH; }
"pop"       { return POP; }
"cpy"|"copy" { return CPY; }
"lt"        { return LT; }
"gt"        { return GT; }
"lte"       { return LTE; }
"gte"       { return GTE; }
"eq"        { return EQ; }
"neq"       { return NEQ; }
"setf"      { return SETF; }
"clrf"      { return CLRF; }
"call"      { return CALL; }
"jmp"       { return JMP; }
"ret"       { return RET; }
"callt"     { return CALLT; }
"jmpt"      { return JMPT; }
"rett"      { return RETT; }
"callf"     { return CALLF; }
"jmpf"      { return JMPF; }
"retf"      { return RETF; }
"add"       { return ADD; }
"sub"       { return SUB; }
"mul"       { return MUL; }
"div"       { return DIV; }
"mod"       { return MOD; }
"addi"      { return ADDI; }
"subi"      { return SUBI; }
"muli"      { return MULI; }
"divi"      { return DIVI; }
"modi"      { return MODI; }
"addu"      { return ADDU; }
"subu"      { return SUBU; }
"mulu"      { return MULU; }
"divu"      { return DIVU; }
"modu"      { return MODU; }
"addf"      { return ADDF; }
"subf"      { return SUBF; }
"mulf"      { return MULF; }
"divf"      { return DIVF; }
"modf"      { return MODF; }
"exit"      { return EXIT; }
"abort"     { return ABORT; }
"nop"       { return NOP; }

"r1"|"r01"          { return R01; }
"r2"|"r02"          { return R02; }
"r3"|"r03"          { return R03; }
"r4"|"r04"          { return R04; }
"r5"|"r05"          { return R05; }
"r6"|"r06"          { return R06; }
"r7"|"r07"          { return R07; }
"r8"|"r08"          { return R08; }
"r9"|"r09"          { return R09; }
"r10"               { return R10; }
"r11"               { return R11; }
"r12"               { return R12; }
"r13"               { return R13; }
"r14"               { return R14; }
"r15"               { return R15; }
"r16"               { return R16; }
"r17"               { return R17; }
"r18"               { return R18; }
"r19"               { return R19; }
"r20"               { return R20; }
"r21"               { return R21; }
"r22"               { return R22; }
"r23"               { return R23; }
"r24"               { return R24; }
"r25"               { return R25; }
"r26"               { return R26; }
"r27"               { return R27; }
"r28"               { return R28; }
"r29"               { return R29; }
"r30"               { return R30; }
"r31"               { return R31; }
"r32"               { return R32; }
"sp"                { return SP; }

"[" { return '['; }
"]" { return ']'; }

"(" { return '('; }
")" { return ')'; }

":" { return ':'; }
"=" { return '='; }

"{" { return '{'; }
"}" { return '}'; }

"+" {return '+'; }
"-" {return '-'; }
"/" {return '/'; }
"*" {return '*'; }
"%" {return '%'; }

"," { return ','; }

(-?[1-9][0-9]*)|0 {
    yylval.ival = strtol(yytext, NULL, 10);
    return INTEGER;
}

0[xX][0-9a-fA-F]+ {
    yylval.uval = (unsigned int)strtol(yytext, NULL, 16);
    return UNSIGNED;
}

-?(0|[1-9][0-9]*)\.([0-9]*([eE][-+]?([1-9][0-9]*))?) {
    yylval.fval = (float)strtod(yytext, NULL);
    return FLOAT;
}

[a-z_][a-z0-9_]* {
    yylval.strg = create_string(yytext);
    return NAME;
}

\" {
    if(strbuf == NULL)
        strbuf = create_string(NULL);
    else
        clear_string(strbuf);
    BEGIN(DQUOTE);
}

<DQUOTE>\n {
    fprintf(stderr, "scanner error: %d: unexpected end of line in literal string\n", yylineno);
    BEGIN(INITIAL);
}

<DQUOTE>\\n { append_string_char(strbuf, '\n'); }
<DQUOTE>\\r { append_string_char(strbuf, '\r'); }
<DQUOTE>\\t { append_string_char(strbuf, '\t'); }
<DQUOTE>\\v { append_string_char(strbuf, '\v'); }
<DQUOTE>\\a { append_string_char(strbuf, '\a'); }
<DQUOTE>\\b { append_string_char(strbuf, '\b'); }
<DQUOTE>\\f { append_string_char(strbuf, '\f'); }
<DQUOTE>\\e { append_string_char(strbuf, '\x1b'); }
<DQUOTE>\\\" { append_string_char(strbuf, '\"'); }
<DQUOTE>\\. { append_string_char(strbuf, yytext[1]); }

<DQUOTE>\\[xX][0-9A-Fa-f]{1,4} {
    int tmp = strtol(&yytext[2], NULL, 16);
    append_string_char(strbuf, tmp);
}

<DQUOTE>\"[ \t]*\\[ \t]*\n[ \t]*\" { /* line ignore continuation */ }

<DQUOTE>[^\\\n\"]+ { append_string(strbuf, yytext); }

<DQUOTE>\" {
    yylval.strg = copy_string(strbuf);
    BEGIN(INITIAL);
    return QSTRG;
}

\' {
    if(strbuf == NULL)
        strbuf = create_string(NULL);
    else
        clear_string(strbuf);
    BEGIN(SQUOTE);
}

<SQUOTE>\'[ \t]*\\[ \t]*\n[ \t]*\' { /* ignore continuation */ }

<SQUOTE>\n {
    fprintf(stderr, "scanner error: %d: unexpected end of line in literal string\n", yylineno);
    BEGIN(INITIAL);
}

<SQUOTE>\\ { append_string_char(strbuf, '\\'); }

<SQUOTE>[^\\\n\']+ { append_string(strbuf, yytext); }

<SQUOTE>\' {
    yylval.strg = copy_string(strbuf);
    BEGIN(INITIAL);
    return QSTRG;
}

"//" { BEGIN(LCOMMENT); }
<LCOMMENT>. {}
<LCOMMENT>[\n\r] { BEGIN(INITIAL); }

"/*" { BEGIN(BCOMMENT); }
<BCOMMENT>[\n\r] {}
<BCOMMENT>. {}
<BCOMMENT>"*/" { BEGIN(INITIAL); }

[ \t\r\n\v\f]+ { /* ignore whitespace */ }

. {
    yyerror("syntax error: invalid character found");
}

<<EOF>> {
    // This code must be inlined because of the heavy use of macros.
    file_t* ptr = get_file_buffer();
    if(ptr) {
        TRACE("end file: %s", raw_string(ptr->name));
        fclose(ptr->fp);
        destroy_string(ptr->name);
        yy_delete_buffer(ptr->buffer);
        pop_file_buffer();
        _FREE(ptr); // using GC, this is a NOOP
        ptr = get_file_buffer();
        if(ptr)
            yy_switch_to_buffer(ptr->buffer);
        else
            yyterminate();
    }
}

%%

