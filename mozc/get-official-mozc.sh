#!/bin/bash

rm -rf mozc-master/
wget -nc https://github.com/google/mozc/archive/master.zip
unzip master.zip
cp mozc-master/src/data/dictionary_oss/id.def .
cat mozc-master/src/data/dictionary_oss/dictionary*.txt > mozcdic.txt
rm -rf mozc-master/
