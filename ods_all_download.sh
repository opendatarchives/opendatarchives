#! /bin/bash

find . -maxdepth 1 -type d | sed 's!^.*/!!' | grep -v '^.$' | sort | parallel --line-buffer -j 4 bash ods_download.sh {}
