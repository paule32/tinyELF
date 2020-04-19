#!/bin/bash

nasm -f bin   -o test2      import@test32.asm
nasm -f elf32 -o wrap32ae.o export@test32.asm

chmod u+x test2

g++-5 -m32 -Werror -fpic -o wrap32ai.o -c wrap32ai.cc
g++-5 -m32 -shared -o libwrap32ae.so \
    wrap32ai.o \
    wrap32ae.o

g++-5 -m32 -o test1 wrap32me.cc -L. -l wrap32ae
strip test1

SAVE_PATH=$LD_LIBRARY_PATH
export LD_LIBRARY_PARG=.;./test2

LD_LIBRARY_PATH=${SAVE_PATH}
