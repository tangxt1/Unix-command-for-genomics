#!/bin/bash
# 13script.sh
# 20 and 100 are being compared as strings. Lexical comparison
[[ 20 > 100 ]]
echo $?
