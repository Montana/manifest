#!/bin/bash

# Author Montana Mendy

tar -xOf file.tar manifest.json | tr , '\n' | grep -o '"Config":".*"' | awk -F ':' '{print $2}' | awk '{print substr($0,2,12)}'
