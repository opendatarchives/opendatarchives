#! /bin/bash
EXCLUSIONS='^(\.|public.opendatasoft)'
JOBS=4
LOG="../ods-$(date +%Y%m%d).log"

date -Iseconds > $LOG
find . -maxdepth 1 -type d | sed 's!^.*/!!' | grep -v '^.$' | egrep -v "$EXCLUSIONS" | sort | parallel --line-buffer -j $JOBS bash ods_update.sh {} >> $LOG
date -Iseconds >> $LOG
