#!/bin/bash
# 11script.sh
f=(1/3)
echo "The value of e is $f"
g=$(echo 1/3 | bc -l)
echo "The value of g is $g"
