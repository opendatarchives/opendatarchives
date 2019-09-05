#! /bin/bash

# Archiveur de portail Koumoul
# écrit par Christian Quest, sous licence WTFPL

KM=$1

mkdir -p "data/$KM/archives/CATALOGUE"
cd "data/$KM"
IFS=$'\n'

# récupération de l'id du site
OWNER=$(curl --compressed -s "https://$KM/datasets" | grep -o owner.*portalId | sed 's/^.*:"//;s/",.*$//')

# liste des datasets
curl --compressed -s "https://koumoul.com/s/data-fair/api/v1/datasets?size=10000&page=1&select=id&owner=$OWNER" | gzip -9 > archives/CATALOGUE/.CATALOGUE.json.gz
JSON_OLD=$(zcat CATALOGUE.json.gz | jq -S .  | md5sum)
JSON_NEW=$(zcat "archives/CATALOGUE/.CATALOGUE.json.gz" | jq -S . | md5sum)
if [ "$JSON_OLD" = "$JSON_NEW" ]
then
  rm "archives/CATALOGUE/.CATALOGUE.json.gz"
else
  NOW=$(date +%Y%m%dT%H%M%S)
  mv "archives/CATALOGUE/.CATALOGUE.json.gz" "archives/CATALOGUE/CATALOGUE_$NOW.json.gz"
  ln -f -s "archives/CATALOGUE/CATALOGUE_$NOW.json.gz" CATALOGUE.json.gz
fi


for DATASET in $(zcat CATALOGUE.json.gz | jq .results[] -c)
do
  ID=$(echo $DATASET | jq -r .id)
  mkdir -p "archives/$ID"
  curl --compressed -s "https://koumoul.com/s/data-fair/api/v1/datasets/$ID" | jq . -S > "archives/$ID/$ID-meta.json"
  DATE=$(jq -r .updatedAt "archives/$ID/$ID-meta.json")
  TIMESTAMP=$(date -d "$DATE" +%Y%m%dT%H%M%SZ)
  JSON_OLD=$(jq -S . $ID-meta.json | md5sum)
  JSON_NEW=$(jq -S . "archives/$ID/$ID-meta.json" | md5sum)
  if [ "$JSON_OLD" = "$JSON_NEW" ]
  then
    rm "archives/$ID/$ID-meta.json"
  else
    NOW=$(date +%Y%m%dT%H%M%S)
    mv "archives/$ID/$ID-meta.json" "archives/$ID/$TIMESTAMP $ID-meta.json"
    ln -f -s "archives/$ID/$TIMESTAMP $ID-meta.json" "$ID-meta.json"
  fi
  FILENAME=$(jq -r .file.name "$ID-meta.json")
  if [ ! -f "archives/$ID/$TIMESTAMP $FILENAME" ] && [ ! -f "archives/$ID/$TIMESTAMP $FILENAME.gz" ]
  then
    echo "down $KM > $ID > $FILENAME $TIMESTAMP"
    curl --compressed -s "https://koumoul.com/s/data-fair/api/v1/datasets/$ID/raw" > "archives/$ID/$TIMESTAMP $FILENAME"

      # peut-on compresser le fichier ?
      GZ=$(echo $FILENAME | egrep "\.(doc|docx|xls|xlsx|csv|json|geojson|xml|txt|rtf|kml|xml|gml)$")
      if [ ! "$GZ" = "" ]
      then
        echo "gzip $KM > $ID > $FILENAME"
        pigz -9 "archives/$ID/$TIMESTAMP $FILENAME"
        FILENAME="$FILENAME.gz"
      fi
    touch -t $(date -d "$DATE" +%Y%m%d%H%M.%S) "archives/$ID/$TIMESTAMP $FILENAME"
    ln -f -s "archives/$ID/$TIMESTAMP $FILENAME" "$ID $FILENAME"
  fi
done
