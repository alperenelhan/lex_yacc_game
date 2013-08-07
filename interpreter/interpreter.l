%{
#include <string.h>
int linenumber=1;
%}

lower			[a-z]
upper			[A-Z]
letter			{upper}|{lower}
lowerdash		_
string			\".+\"
ws		        [ \t]+
digit			[0-9]
posnum			{digit}+
int				{posnum}
true			"TRUE"|"true"
false			"FALSE"|"false"
bool			{true}|{false}
if				if
fi              fi
else			else
while			while
name			{letter}({digit}|{lowerdash}|{letter})*
createrealm		create_realm
showrealm		show_realm
addpaladin		addpaladin
deletepaladin	rmpaladin
changepaladin	replace
run				run
eq				=
gre				>=
sme				<=
equ				==
sm				<
gr				>
nequ			!=
newline			[\n]
%%

{if}	return IF;
{fi}    return FI;
{else}	return ELSE;
{while}	return WHILE;
{int}	{ yylval.yvalue = atoi(yytext); return INT;}
\'.\'   { yylval.ychar = yytext[1]; return CHAR;}
\+		return ADD;
\-		return SUB; 
\*		return MUL;
\/		return DIV;
\(		return LEFTP;
\)		return RIGHTP;
\{		return LEFTCB;
\}		return RIGHTCB;
\[		return LEFTB;
\]		return RIGHTB;
\;		return SCOL;
\,		return COMMA;
"echo" return ECHO;
{equ} return EQU;
{gre} return GRE;
{sme} return SME;
{gr} return GR;
{sm} return SM;
{nequ} return NEQU;
{eq}	return EQ;
{addpaladin} return APALADIN;
{deletepaladin} return DPALADIN;
{changepaladin} return CPALADIN;
{createrealm} return CREALM;
{showrealm} return SREALM;
{run}       return RUN;	
{name}	{ yylval.yname = strdup(yytext); return NAME;}
{newline}	{linenumber++; ;}
{ws}	;

%%

int yywrap() { return 1; }
