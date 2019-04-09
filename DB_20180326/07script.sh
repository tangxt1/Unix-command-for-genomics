#!/bin/bash
# 07script.sh
a=$(ping -c 1 google.com | grep 'bytes from' | cut -d = -f 4)
echo "The ping was $a"
