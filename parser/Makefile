COMPILER = gcc
BIN = parser
LEX = parser.l
YACC = parser.y
FLAG = -lfl
LEXER = flex
PARSER = yacc
REMOVE = rm -f

all :
	  ${LEXER} ${LEX}
	  ${PARSER} ${YACC}
	  ${COMPILER} -o ${BIN} y.tab.c ${FLAG}

clean :
	   ${REMOVE} ${BIN} lex.yy.c y.tab.c



