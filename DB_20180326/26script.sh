#!/bin/bash
# 26script.sh
while getopts u:p: option;do
    case $option in
	u) user=$OPTARG;;
	p) pass=$OPTARG;;
    esac
done
echo "User: $user / Passwd: $pass"
