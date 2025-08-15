%option noyywrap
%option yylineno

%{
#include "parser.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%%

[0-9]+ {
    yylval.num = atoi(yytext);
    return NUMBER;
}

\"(\\.|[^\"])*\" {
    yylval.str = strdup(yytext + 1);
    yylval.str[strlen(yylval.str) - 1] = '\0';
    return STRING;
}

"true"|"false" {
    yylval.str = strdup(yytext);
    return BOOL;
}

[a-zA-Z_][a-zA-Z0-9_]* {
    // Keywords (keep these as separate tokens)
    if (strcmp(yytext, "form") == 0) return FORM;
    if (strcmp(yytext, "meta") == 0) return META;
    if (strcmp(yytext, "section") == 0) return SECTION;
    if (strcmp(yytext, "field") == 0) return FIELD;
    if (strcmp(yytext, "validate") == 0) return VALIDATE;
    if (strcmp(yytext, "if") == 0) return IF;
    if (strcmp(yytext, "error") == 0) return ERROR;
    // Attribute keywords
    if (strcmp(yytext, "required") == 0) return REQUIRED;
    if (strcmp(yytext, "default") == 0) return DEFAULT;
    if (strcmp(yytext, "min") == 0) return MIN;
    if (strcmp(yytext, "max") == 0) return MAX;
    if (strcmp(yytext, "pattern") == 0) return PATTERN;
    if (strcmp(yytext, "accept") == 0) return ACCEPT;
    if (strcmp(yytext, "rows") == 0) return ROWS;
    if (strcmp(yytext, "cols") == 0) return COLS;
    if (strcmp(yytext, "options") == 0) return OPTIONS;

    // All other words are identifiers, including field types like "text", "email"
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}

"["     { return LBRACK; }
"]"     { return RBRACK; }
"{"     { return LBRACE; }
"}"     { return RBRACE; }
":"     { return COLON; }
";"     { return SEMI; }
","     { return COMMA; }
"="     { return EQ; }
"<"     { return LT; }
">"     { return GT; }

[ \t\n\r]+  ;  // Skip whitespace

. {
    fprintf(stderr, "Unknown character '%s' at line %d\n", yytext, yylineno);
    return -1;
}

%%