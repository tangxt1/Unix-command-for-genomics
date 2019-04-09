#!/bin/bash
# 27script.sh
while getopts u:p:ab option;do
    case $option in
	u) user=$OPTARG;;
	p) pass=$OPTARG;;
	a) echo "Got the A Flag";;
	b) echo "Got the B Flag";;
    esac
done
echo "User: $user / Passwd: $pass"
