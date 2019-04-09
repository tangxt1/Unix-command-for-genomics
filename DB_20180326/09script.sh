#!/bin/bash
# 09script.sh
d=2
e=$((d+2))
echo "The value of e is $e"
((e++))
echo "The value of e is $e"
((e--))
echo "The value of e is $e"
((e+=5))
echo "The value of e is $e"
((e*=3))
echo "The value of e is $e"
((e/=3))
echo "The value of e is $e"
((e-=5))
echo "The value of e is $e"
