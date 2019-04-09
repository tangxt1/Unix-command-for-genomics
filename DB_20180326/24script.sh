#!/bin/bash
# 24script.sh
function numberthings {
    i=1
    for f in $@;do
	echo $i: $f
	((i+=1))
    done
}
numberthings $(ls)
