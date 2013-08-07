%{ 
#include <stdio.h> 
#include <stdlib.h> 
#include <stdarg.h> 
#include <string.h>
#include <time.h>

typedef struct paladin {
	char id;
	int speed;
	int direction;
	int xpos;
	int ypos;
	struct paladin *next;
} paladin;
typedef struct paladin *palptr;

typedef struct var {
    char* varname;
    int varvalue;
    struct var *node;
}var;
typedef struct var *varptr;

typedef struct { 
    int convalue;
} constant; 

typedef struct { 
    char charvalue;
} charconst;

typedef struct { 
    var i;
} variables; 

typedef struct { 
    int oper;
    int params;
    struct typeptrTag **operands;
} operator; 

typedef struct typeptrTag { 
    enum { constant_t, variable_t, operator_t, char_t} type_t;
    union { 
        constant con;
	    variables vars;
	    operator opr;
	    charconst ch;
    };
} typeptr; 


varptr varhead = NULL;
palptr palhead = NULL;
char realm[50][150];


void yyerror(char *s);
typeptr *confunc(int value);
typeptr *charfunc(char value);
typeptr *varfunc(char *i);
typeptr *operfunc(int oper, int params, ...);
void varlist(char* name);
varptr find(char *name);
void freevariables();
void freeAll(typeptr *p);
int construct(typeptr *p);

void addpaladin(int speed,char id);
void freepaladinlist();
void rmpaladin(char id);
void create_realm();
void show_realm();
void replace(char id, int speed, int direction, int xpos, int ypos );
void run(int time);

%} 

%union { 
    int yvalue;
    char ychar;
    char *yname;
    typeptr *ynode;
};
%token <yvalue> INT
%token <ychar> CHAR  
%token <yname> NAME
%token IF FI ELSE WHILE QUIT APALADIN DPALADIN SREALM CREALM CPALADIN RUN LEFTP RIGHTP LEFTCB RIGHTCB LEFTB RIGHTB SCOL COMMA ECHO NEWLINE
%left ADD MUL DIV SUB EQ EQU GRE SME GR SM NEQU
%type <ynode> stm expr varassign whilestm ifstm stmlist condition factor term id funcs
  
%% 
start: all        { freevariables(); exit(0); }
; 

all: 
| all stm         { construct($2); freeAll($2); }
; 
stm: SCOL         { $$ = operfunc(SCOL, 2, NULL, NULL); } 
| expr SCOL       { $$ = $1; } 
| ECHO expr SCOL  { $$ = operfunc(ECHO, 1, $2); } 
| varassign       { $$ = $1; } 
| whilestm        { $$ = $1; } 
| ifstm           { $$ = $1; }
| funcs           { $$ = $1; }
; 


stmlist: stm      { $$ = $1; } 
| stmlist stm     { $$ = operfunc(SCOL, 2, $1, $2); } 
; 

ifstm: IF LEFTP condition RIGHTP LEFTCB stmlist RIGHTCB FI  { $$ = operfunc(IF, 2, $3, $6); } 
| IF LEFTP condition RIGHTP LEFTCB stmlist RIGHTCB ELSE LEFTCB stmlist RIGHTCB  { $$ = operfunc(IF, 3, $3, $6, $10); }
;

whilestm: WHILE LEFTP condition RIGHTP LEFTCB stmlist RIGHTCB   { $$ = operfunc(WHILE, 2, $3, $6); } 
;

condition: NAME     { $$ = varfunc($1); } 
| INT               { $$ = confunc($1); } 
| expr EQU expr     { $$ = operfunc(EQU, 2, $1, $3); }
| expr GRE expr     { $$ = operfunc(GRE, 2, $1, $3); }
| expr SME expr     { $$ = operfunc(SME, 2, $1, $3); }
| expr GR expr      { $$ = operfunc(GR, 2, $1, $3); }
| expr SM expr      { $$ = operfunc(SM, 2, $1, $3); }
| expr NEQU expr    { $$ = operfunc(NEQU, 2, $1, $3); }
;

varassign: NAME EQ expr SCOL { $$ = operfunc(EQ, 2, varfunc($1), $3); } 
;

funcs: CREALM LEFTP RIGHTP SCOL { $$ = operfunc(CREALM, 0); }
| SREALM LEFTP RIGHTP SCOL { $$ = operfunc(SREALM, 0); }
| APALADIN LEFTP INT COMMA CHAR RIGHTP SCOL { $$ = operfunc(APALADIN, 2, confunc($3), charfunc($5)); }
| DPALADIN LEFTP CHAR RIGHTP SCOL { $$ = operfunc(DPALADIN, 1, charfunc($3)); }
| CPALADIN LEFTP CHAR COMMA INT COMMA INT COMMA INT COMMA INT RIGHTP SCOL { $$ = operfunc(CPALADIN, 5, charfunc($3), confunc($5), confunc($7), confunc($9), confunc($11)); }
| RUN LEFTP INT RIGHTP SCOL { $$ = operfunc(RUN, 1, confunc($3)); }
;


expr: expr ADD term { $$ = operfunc(ADD, 2, $1, $3); } 
| expr SUB term     { $$ = operfunc(SUB, 2, $1, $3); }
| term              { $$ = $1; } 
;

term: term MUL factor   { $$ = operfunc(MUL, 2, $1, $3); } 
| term DIV factor       { $$ = operfunc(DIV, 2, $1, $3); } 
| factor                { $$ = $1; } 
;

factor: LEFTP expr RIGHTP  { $$ = $2; } 
| id    { $$ = $1; } 
;

id: INT { $$ = confunc($1); } 
| NAME  { $$ = varfunc($1); }
| CHAR  { $$ = charfunc($1); }
;

  
%% 
#include "lex.yy.c"

varptr find(char *name){
    varptr temp = varhead;
    if(!temp)
        return NULL;
    for(;temp->node; temp=temp->node){
        if(!strcmp(temp->node->varname,name)){
            return temp->node;
        }
    }
    return NULL;
}

void varlist(char* name){
    varptr temp;
    varptr p = (varptr) malloc(sizeof(var));
    p->varname = strdup(name);
    p->node = NULL;
    if(!varhead)
        varhead = (varptr) malloc(sizeof(var));
    if(!(temp=find(name))){
        for(temp=varhead;temp->node;temp=temp->node);
        temp->node = p;
    }
}

typeptr *confunc(int value) { 
    typeptr *p; 
    p = malloc(sizeof(typeptr));
    p->type_t = constant_t; 
    p->con.convalue = value;
    return p; 
}

typeptr *charfunc(char value) { 
    typeptr *p; 
    p = malloc(sizeof(typeptr));
    p->type_t = char_t; 
    p->ch.charvalue = value; 
    return p; 
}
 
typeptr *varfunc(char *i) { 
    typeptr *p; 
    p = malloc(sizeof(typeptr));
    p->type_t = variable_t; 
    p->vars.i.varname = strdup(i);
    varlist(i);
    return p; 
} 
typeptr *operfunc(int oper, int params, ...) { 
    va_list ap; 
    typeptr *p; 
    int i; 
    p = malloc(sizeof(typeptr));
    p->opr.operands = malloc(params * sizeof(typeptr)); 
    p->type_t = operator_t; 
    p->opr.oper = oper; 
    p->opr.params = params; 
    va_start(ap, params); 
    for (i = 0; i < params; i++){
        p->opr.operands[i] = va_arg(ap, typeptr*);
    }
    va_end(ap); 
    return p; 
} 

void freevariables(){
    varptr temp;
    if(varhead){	
	for(;varhead->node;){
	    temp = varhead;
	    varhead = varhead->node;
	    free(temp);
	}
	free(varhead);
    }
}
void freeAll(typeptr *p) { 
    int i;
    if (!p) return; 
    if (p->type_t == operator_t) { 
        for (i = 0; i < p->opr.params; i++) 
            freeAll(p->opr.operands[i]); 
        free(p->opr.operands); 
    } 
    free (p);
} 

int construct(typeptr *p) { 
    if (!p) 
        return 0; 
    if(p->type_t == constant_t)
        return p->con.convalue; 
    else if(p->type_t == variable_t) {
        varptr temp;
    	temp = find(p->vars.i.varname);
        if(temp)
            return temp->varvalue;
    }
    else if(p->type_t == char_t){
        return p->ch.charvalue;
    }
    else if(p->type_t == operator_t){
        if(p->opr.oper == IF){
            if(construct(p->opr.operands[0]))
              construct(p->opr.operands[1]); 
            else if (p->opr.params > 2) 
                construct(p->opr.operands[2]); 
            return 0;
        }
        else if(p->opr.oper == WHILE){
            while(construct(p->opr.operands[0])){
                construct(p->opr.operands[1]);
            }
            return 0;
        }
        else if(p->opr.oper == APALADIN){
            addpaladin(p->opr.operands[0]->con.convalue, (char)p->opr.operands[1]->ch.charvalue);
        }
        else if(p->opr.oper == DPALADIN){
            rmpaladin(p->opr.operands[0]->ch.charvalue);
        }
        else if(p->opr.oper == CPALADIN){
            replace(p->opr.operands[0]->ch.charvalue, p->opr.operands[1]->con.convalue, p->opr.operands[2]->con.convalue, p->opr.operands[3]->con.convalue, p->opr.operands[4]->con.convalue );
        }
        else if(p->opr.oper == SREALM){
            show_realm();
        }
        else if(p->opr.oper == CREALM){
            create_realm();
        }
        else if(p->opr.oper == RUN){
            run(p->opr.operands[0]->con.convalue);
        }                                        
        else if(p->opr.oper == ECHO){
            printf("%d\n", construct(p->opr.operands[0]));
            return 0;
        }
        else if(p->opr.oper == EQ){
            varptr temp = find(p->opr.operands[0]->vars.i.varname);
            if(temp)
                return temp->varvalue = construct(p->opr.operands[1]);
        }
        else if(p->opr.oper == SCOL){
            construct(p->opr.operands[0]);
            return construct(p->opr.operands[1]);
        }
        else if(p->opr.oper == ADD)
            return construct(p->opr.operands[0]) + construct(p->opr.operands[1]); 
        else if(p->opr.oper == SUB)
            return construct(p->opr.operands[0]) - construct(p->opr.operands[1]); 
        else if(p->opr.oper == MUL)
            return construct(p->opr.operands[0]) * construct(p->opr.operands[1]); 
        else if(p->opr.oper == DIV)
            return construct(p->opr.operands[0]) / construct(p->opr.operands[1]); 
        else if(p->opr.oper == SM)
            return construct(p->opr.operands[0]) < construct(p->opr.operands[1]); 
        else if(p->opr.oper == GR)
            return construct(p->opr.operands[0]) > construct(p->opr.operands[1]); 
        else if(p->opr.oper == GRE)
            return construct(p->opr.operands[0]) >= construct(p->opr.operands[1]); 
        else if(p->opr.oper == SME)
            return construct(p->opr.operands[0]) <= construct(p->opr.operands[1]); 
        else if(p->opr.oper == NEQU)
            return construct(p->opr.operands[0]) != construct(p->opr.operands[1]); 
        else if(p->opr.oper == EQU)
            return construct(p->opr.operands[0]) == construct(p->opr.operands[1]); 

    }
    return 0; 
}

void addpaladin(int speed,char id){
	if(realm[0][0] != '#'){
		printf("Paladin couldn't added. No world found!\n");
		return;
	}
	if(!palhead){
		palhead = (palptr) malloc(sizeof(paladin));
		palhead->next=NULL;
	}
	palptr pal= (palptr) malloc(sizeof(paladin));
	pal->id=id;
	pal->speed=speed;
	do{
		srand(time(NULL));
		pal->xpos=rand()%49+1;
		srand(time(NULL));
		pal->ypos=rand()%149+1;
	}while(realm[pal->xpos][pal->ypos] != ' ' );
	srand(time(NULL));
	pal->direction=rand()%4+1;
	realm[pal->xpos][pal->ypos]=pal->id;
	pal->next = NULL;
    palptr tmp = palhead;
    for(;tmp->next;tmp=tmp->next)
        if(tmp->next->id == id)
            break;
    if(!tmp->next){
        tmp->next = pal;
        printf("Paladin added to realm :\tID: %c\n\t\t\t\tSPEED: %d\n\t\t\t\tDIRECTION: %d\n\t\t\t\tXPOS: %d\n\t\t\t\tYPOS: %d\n\n",pal->id,pal->speed, pal->direction, pal->xpos, pal->ypos);
    }
    else{
        printf("Paladin with given id is already exists!\n\n");
    }

}

void freepaladinlist(){
    palptr rm;
    if(!palhead)
        return;
    while(palhead->next){
        rm = palhead;
        palhead= palhead->next;
        free(rm);
    }
    free(palhead);
}

void rmpaladin(char id){
    palptr p = palhead;
    palptr rm;
    if(!p){
        printf("There is no paladin in realm. First add some!\n");
		return;
    }
    for(;p->next;){
        if(p->next->id == id){
            rm = p->next;
            printf("Paladin \'%c\' removed from realm!\n", rm->id);
            realm[rm->xpos][rm->ypos] = ' ';
            p->next = rm->next;
            free(rm);
        }
        else{
            p=p->next;
        }
     }
}

void create_realm(){
    int i, j;	
	for(i=0 ; i<50 ; i++){
		for(j=0 ; j<150 ; j++){
			if(i == 0 || i==49 || j==0 || j==149)
				realm[i][j]='#';
			else
				realm[i][j]=' ';
		}
	}
	for(j=0;j<=40;j++)
		if(j>=15 && j<=23)
			realm[12][j]=' ';
		else
			realm[12][j]='#';
	for(i=5;i<=12;i++)
		realm[i][40]='#';
	for(i=13;i<=40;i++)
		if(i >= 16 && i <= 20)
			realm[i][30]=' ';
		else
			realm[i][30]='#';
	for(j=49;j<125;j++)
		if(j>=85 && j<=93 )
			realm[24][j]=' ';
		else
			realm[24][j]='#';
	for(i=24;i<50;i++)
		if(i>=30 && i<=35)
			realm[i][74]=' ';
		else
			realm[i][74]='#';
	for(i=0;i<25;i++)
		if(i>=8 && i<=13)
			realm[i][105]=' ';
		else
			realm[i][105]='#';
	printf("Realm Created!\n");
}

void show_realm(){
    int i, j;
	if(realm[0][0] != '#'){
		printf("First create a realm to show it.\n");
		return;
	}
	for(i=0 ; i<50 ; i++){
		for(j=0 ; j<150 ; j++){
			printf("%c",realm[i][j]);
		}
		printf("\n");
	}
}

void replace(char id, int speed, int direction, int xpos, int ypos ){
    palptr p = palhead;
    if(!p){
        printf("Paladin couldn't find. First add some!\n");  
    }
    for(;p->next;p=p->next)
        if(p->next->id == id)
            break;
    if(p->next){
        p->next->speed = speed;
        if(direction<1 || direction >4)
            printf("Direction couldn't change, It must be between 1-4.\n");
        else
            p->next->direction = direction;
        if( (xpos>=49 || xpos<=0) || (ypos<=0 || ypos>=149) || realm[xpos][ypos] != ' ')
            printf("Coordinates couldn't change, because there is already a block or enemy at that coordinates. But other given attributes has changed.\n");
        else{
            realm[p->next->xpos][p->next->ypos] = ' ';
            p->next->xpos = xpos;
            p->next->ypos = ypos;
            realm[p->next->xpos][p->next->ypos] = id;
        }

    }
    else{
        printf("Couldn't find the paladin with given ID.\n");
    }
        
}

void run(int vartime){
	int i;
	palptr temp = palhead;
	palptr rm;
	if(!temp){
	    printf("Nothing happens because there is no paladins!\n");
	    return;
	}
	for(i=0;i<vartime;i++){
	    for(temp=palhead;temp->next;){
	        switch(temp->next->direction){
	            case 1:{
	                temp->next->xpos -= temp->next->speed;
	                if(temp->next->xpos > 0 && realm[temp->next->xpos][temp->next->ypos] == ' '){
	                    int i, control=0;
    	                for(i=temp->next->speed;i>0;i--){
	                        if(realm[temp->next->xpos+i-1][temp->next->ypos] != ' '){
	                            control=1;
	                            break;
	                        }
	                    }
	                    if(control==1){
	                        temp->next->xpos += temp->next->speed;
	                        int tmp;
	                        do{
	                            srand( time ( NULL ) );
	                            tmp = rand()%4+1;
	                            srand( time ( NULL ) );
	                        }while(tmp == temp->next->direction);
	                        temp->next->direction = tmp;
	                        printf("Hero \'%c\' couldn't move. It changes his direction to %d\n",temp->next->id, temp->next->direction);	                                              
	                    }
	                    else{
	                        realm[temp->next->xpos+temp->next->speed][temp->next->ypos] = ' ';
	                        realm[temp->next->xpos][temp->next->ypos] = temp->next->id;
	                        printf("Hero \'%c\' moves to (%d, %d)\n",temp->next->id, temp->next->xpos, temp->next->ypos);
                        }
                        temp=temp->next;
	                }
	                else{
	                    if(temp->next->xpos <= 0 || realm[temp->next->xpos][temp->next->ypos] == '#')
	                        printf("Player \'%c\' hit the wall and died!\n", temp->next->id);
	                    else
	                        printf("Player \'%c\' beaten by the player \'%c\' and died!\n", temp->next->id, realm[temp->next->xpos][temp->next->ypos]);
	                    rm=temp->next;
                        realm[temp->next->xpos+temp->next->speed][temp->next->ypos] = ' ';
	                    temp->next=rm->next;
	                    free(rm);
	                }
	                break;
	            }
	            case 2:{
	                temp->next->ypos += temp->next->speed;
	                if(temp->next->ypos < 149 && realm[temp->next->xpos][temp->next->ypos] == ' '){
                        int i, control=0;
    	                for(i=temp->next->speed;i>0;i--){
	                        if(realm[temp->next->xpos][temp->next->ypos-i+1] != ' '){
	                            control=1;
	                            break;
	                        }
	                    }
	                    if(control==1){
	                        temp->next->ypos -= temp->next->speed;
	                        int tmp;
	                        do{
	                            srand( time ( NULL ) );
	                            tmp = rand()%4+1;
	                            srand( time ( NULL ) );
	                        }while(tmp == temp->next->direction);
	                        temp->next->direction = tmp;
	                        printf("Hero \'%c\' couldn't move. It changes his direction to %d\n",temp->next->id, temp->next->direction);	                                              
	                    }
	                    else{     	                
	                        realm[temp->next->xpos][temp->next->ypos - temp->next->speed] = ' ';
	                        realm[temp->next->xpos][temp->next->ypos] = temp->next->id;
	                        printf("Hero \'%c\' moves to (%d, %d)\n",temp->next->id, temp->next->xpos, temp->next->ypos);
                        }
                        temp=temp->next;
	                }
	                else{
	                    if(temp->next->ypos >= 149 || realm[temp->next->xpos][temp->next->ypos] == '#')
	                        printf("Player \'%c\' hit the wall and died!\n", temp->next->id);
	                    else
	                        printf("Player \'%c\' beaten by the player \'%c\' and died!\n", temp->next->id, realm[temp->next->xpos][temp->next->ypos]);	                
            	        rm=temp->next;
                        realm[rm->xpos][rm->ypos-temp->next->speed] = ' ';
	                    temp->next=rm->next;
	                    free(rm);
	                }
	                break;
	            }
	            case 3:{
	                temp->next->xpos += temp->next->speed;
	                if(temp->next->xpos < 49  && realm[temp->next->xpos][temp->next->ypos] == ' '){
                        int i, control=0;
    	                for(i=temp->next->speed;i>0;i--){
	                        if(realm[temp->next->xpos-i+1][temp->next->ypos] != ' '){
	                            control=1;
	                            break;
	                        }
	                    }
	                    if(control==1){
	                        temp->next->xpos -= temp->next->speed;
	                        int tmp;
	                        do{
	                            srand( time ( NULL ) );
	                            tmp = rand()%4+1;
	                            srand( time ( NULL ) );
	                        }while(tmp == temp->next->direction);
	                        temp->next->direction = tmp;
	                        printf("Hero \'%c\' couldn't move. It changes his direction to %d\n",temp->next->id, temp->next->direction);
	                    }
	                    else{                      	                
	                        realm[temp->next->xpos-temp->next->speed][temp->next->ypos] = ' ';
	                        realm[temp->next->xpos][temp->next->ypos] = temp->next->id;
	                        printf("Hero \'%c\' moves to (%d, %d)\n",temp->next->id, temp->next->xpos, temp->next->ypos);
                        }
	                    temp=temp->next;
	                }
	                else{
	                    if(temp->next->xpos >= 49 || realm[temp->next->xpos][temp->next->ypos] == '#')
	                        printf("Player \'%c\' hit the wall and died!\n", temp->next->id);
	                    else
	                        printf("Player \'%c\' beaten by the player \'%c\' and died!\n", temp->next->id, realm[temp->next->xpos][temp->next->ypos]);	                
	                    rm=temp->next;
                        realm[rm->xpos-temp->next->speed][rm->ypos] = ' ';
	                    temp->next=rm->next;
	                    free(rm);	                    
	                }
	                break;
	            }
	            case 4:{
	                temp->next->ypos -= temp->next->speed;
	                if(temp->next->ypos > 0 && realm[temp->next->xpos][temp->next->ypos] == ' '){
                        int i, control=0;
    	                for(i=temp->next->speed;i>0;i--){
	                        if(realm[temp->next->xpos][temp->next->ypos+i-1] != ' '){
	                            control=1;
	                            break;
	                        }
	                    }
	                    if(control==1){
	                        temp->next->ypos += temp->next->speed;
	                        int tmp;
	                        do{
	                            srand( time ( NULL ) );
	                            tmp = rand()%4+1;
	                            srand( time ( NULL ) );
	                        }while(tmp == temp->next->direction);
	                        temp->next->direction = tmp;
	                        printf("Hero \'%c\' couldn't move. It changes his direction to %d\n",temp->next->id, temp->next->direction);
	                    }
	                    else{               
	                        realm[temp->next->xpos][temp->next->ypos+temp->next->speed] = ' ';
	                        realm[temp->next->xpos][temp->next->ypos] = temp->next->id;
	                        printf("Hero \'%c\' moves to (%d, %d)\n",temp->next->id, temp->next->xpos, temp->next->ypos);
                        }
	                    temp=temp->next;
	                }
	                else{
	                    if(temp->next->ypos <= 0 || realm[temp->next->xpos][temp->next->ypos] == '#')
	                        printf("Player \'%c\' hit the wall and died!\n", temp->next->id);
	                    else
                            printf("Player \'%c\' beaten by the player \'%c\' and died!\n", temp->next->id, realm[temp->next->xpos][temp->next->ypos]);	                
	                    rm=temp->next;
                        realm[rm->xpos][rm->ypos+temp->next->speed] = ' ';
	                    temp->next=rm->next;
	                    free(rm);	                    
	                }
	                break;
	            }	            	            	            
	        }
	    }
	}
    show_realm();
}

void yyerror(char *s){
	printf("%s around line no %d\n",s, linenumber );
}

int main(void) { 
    yyparse();
    freepaladinlist();
    return 0; 
} 
