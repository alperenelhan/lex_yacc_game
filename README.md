lex_yacc_game
=============

A simple game interpreter and parser written in lex and yacc

To run parser
-------------
```
cd parser
make
./parser < ../test.txt
```
Output should say `Done`.

To run interpreter
-------------
```
cd interpreter
make
./interpreter < ../test.txt
```
You should see the output of the game.

To clean
-------------
Just run
```
make clean
```