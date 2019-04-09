#!/bin/bash
# 22script.sh
a="cat"
case $a in
    cat)       echo "Feline";;
    dog|puppy) echo "Canine";;
    *)         echo "No Match";;
    esac
