%{
void yyerror(char *s);
%}

%token IF ELSE INT CHAR FI NAME WHILE RETURN APALADIN DPALADIN SREALM CREALM CPALADIN RUN LEFTP RIGHTP LEFTCB RIGHTCB LEFTB RIGHTB SCOL COMMA ECHO NEWLINE
%left ADD MUL DIV SUB EQ EQU GRE SME GR SM NEQU

%%
start: all
; 

all: 
| all stm
; 
stm: SCOL
| expr SCOL
| ECHO expr SCOL
| varassign
| whilestm
| ifstm
| funcs
; 


stmlist: stm
| stmlist stm
; 

ifstm: IF LEFTP condition RIGHTP LEFTCB stmlist RIGHTCB FI
| IF LEFTP condition RIGHTP LEFTCB stmlist RIGHTCB ELSE LEFTCB stmlist RIGHTCB 
;

whilestm: WHILE LEFTP condition RIGHTP LEFTCB stmlist RIGHTCB 
;

condition: NAME
| INT
| expr EQU expr 
| expr GRE expr 
| expr SME expr
| expr GR expr 
| expr SM expr
| expr NEQU expr
;

varassign: NAME EQ expr SCOL
;

funcs: CREALM LEFTP RIGHTP SCOL
| SREALM LEFTP RIGHTP SCOL
| APALADIN LEFTP INT COMMA CHAR RIGHTP SCOL
| DPALADIN LEFTP CHAR RIGHTP SCOL
| CPALADIN LEFTP CHAR COMMA INT COMMA INT COMMA INT COMMA INT RIGHTP SCOL
| RUN LEFTP INT RIGHTP SCOL
;


expr: expr ADD term
| expr SUB term
| term
;

term: term MUL factor 
| term DIV factor
| factor
;

factor: LEFTP expr RIGHTP
| id
;

id: INT 
| NAME
| CHAR
;



%%

#include "lex.yy.c"

int main(){
	yyparse();
	printf("Done!\n");
	return 0;
}

void yyerror(char *s){
	printf("%s around line no %d\n",s, linenumber );
}
