#!/bin/bash
# 28script.sh
while getopts :u:p:ab option;do
    case $option in
	u) user=$OPTARG;;
	p) pass=$OPTARG;;
	a) echo "Got the A Flag";;
	b) echo "Got the B Flag";;
	?) echo "I do not know what $OPTARG is!";;
    esac
done
echo "User: $user / Passwd: $pass"
