#! /bin/bash

# script écrit par Christian Quest, sous licence WTFPL

EXCLUSIONS="(public.opendatasoft|orthophoto)"
FILETYPES="(jpg|jpeg|png|pdf|tif|zip|7z|tgz|taz|gz|rar|doc|docx|xls|xlsx|ppt|pptx|odt|ods|odp|gpkg)"
MAXFILES=2000

# domaine du portail OpenDataSoft à archiver
ODS=$(echo $1 | sed 's!/!!g')

WGET='wget -nc '
GZIP='pigz -9 --rsyncable '

IFS=$'\n'
# liste des jeux de données contenant des liens vers des fichiers
DATASETS=$(egrep -Hc '"(file|url|Fichier)"' $ODS/*.json | grep -v ':0' | sed 's/-meta.json:.*$//;s!^.*/!!' | grep "" | egrep -v "$EXCLUSIONS")

for ID in $DATASETS
do
  FIELDS=$(jq -c .fields[] "$ODS/$ID-meta.json" | egrep '"type":"file"' | jq .name -r)
  for F in $FIELDS
  do
    mkdir -p "$ODS/archives/$ID/files"
    # fichier local au portail, le détail n'est dispo qu'en json
    echo "json $ODS > $ID >> $F > $FILENAME"
    curl --compressed --insecure -sS "https://$ODS/explore/dataset/$ID/download/?format=json&timezone=Europe/Berlin" | jq .[].fields.$F -c | egrep -v "(null|^$)" | egrep -v "$EXCLUSIONS" | sort -u > $ODS/.dl
    NB=$(cat $ODS/.dl | wc -l)
    echo "$ODS > $ID >> $F -> TOTAL $NB"
    if [ $NB -lt $MAXFILES ]
    then
      for L in $(cat $ODS/.dl)
      do
        FILENAME=$(echo $L | jq .filename -r )
        if [ ! -f "$ODS/archives/$ID/files/$FILENAME" ]
        then
          echo "down $ODS > $ID >> $F > $FILENAME"
          URL="https://$ODS/explore/dataset/$ID/files/$(echo $L | jq .id -r )/download/"
          mkdir -p "$ODS/archives/$ID/files/$(dirname $FILENAME)"
          wget -q -c -T 10 $URL -O "$ODS/archives/$ID/files/$FILENAME" || rm -f "$ODS/archives/$ID/files/$FILENAME" > /dev/null
        fi
      done
    fi
    rm $ODS/.dl
  done

  # nom du champ contenant le lien vers un fichier externe
  FIELDS=$(jq -c .fields[] "$ODS/$ID-meta.json" | egrep '"(url|Fichier)"' | jq .label -r)
  for F in $FIELDS
  do
    mkdir -p "$ODS/archives/$ID/files"
    zcat "$ODS/$ID.csv.gz" | csvcut -z 500000 -d ';' -c $F | grep -v '/catalog/datasets/' | egrep "(http|ftp).*\.$FILETYPES$" | sed 's/ /%20/g' | egrep -v "$EXCLUSIONS" > $ODS/.dl
    NB=$(cat $ODS/.dl | wc -l)
    echo "$ODS > $ID > $F -> TOTAL $NB"
    if [ $NB -lt $MAXFILES ]
    then
      # url externe au portail
      for L in $(cat $ODS/.dl)
      do
        # quel type de contenu ?
        # TYPE=$(curl -L -I "$L" -s | grep -i 'Content-Type' | tail -n 1)
        FILENAME=$(echo $L | sed 's!^.*/!!;s/%20/ /g')
        if [ ! -f "$ODS/archives/$ID/files/$FILENAME" ]
        then
            echo "down $ODS > $ID > $F > $FILENAME"
            mkdir -p "$ODS/archives/$ID/files/$(dirname $FILENAME)"
            wget -q -c -T 10 $L -O "$ODS/archives/$ID/files/$FILENAME" || rm -f "$ODS/archives/$ID/files/$FILENAME"
        fi
      done
    fi
    rm $ODS/.dl
  done
done

echo "$ODS: fin"
