#!/bin/bash

# Author Montana Mendy

docker history -q IMAGE_HERE | grep -v missing && tar -xOf file.tar manifest.json | tr , '\n' | grep -o '"Config":".*"' | awk -F ':' '{print $2}' | awk '{print substr($0,2,12)}'

# Alternatively, you could use this script: 

# tar -xOf file.tar manifest.json | tr , '\n' | grep -o '"Config":".*"' | awk -F ':' '{print $2}' | awk '{print substr($0,2,12)}'
