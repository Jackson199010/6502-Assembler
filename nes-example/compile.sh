#! /bin/bash

set -e

bash clean.sh

echo Compiling...
ca65 example.s -g -o example.o

echo Linking...
ld65 -o example.nes -C example.cfg example.o -m example.map.txt -Ln example.labels.txt --dbgfile example.dbg

echo Success!