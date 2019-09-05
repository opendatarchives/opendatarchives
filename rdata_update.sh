#! /bin/bash

RDATA=$1
IFS=$'\n'

EXCLUSIONS="(Licence|OGC)"
FORCE="1"

mkdir -p data/$RDATA/archives/CATALOGUE
cd data/$RDATA

source .params

# téléchargement du catalogue de métadonnées
curl -s --compressed -f "https://$API/catalogue/srv/fre/q?_content_type=json&resultType=details&fast=index&buildSummary=false" | jq . -S | gzip -9 > archives/CATALOGUE/.CATALOGUE.json.gz || exit
OLD=$(zcat CATALOGUE.json.gz | jq . -S | md5sum)
NEW=$(zcat archives/CATALOGUE/.CATALOGUE.json.gz | jq . -S | md5sum)
if [ "$NEW" = "$FORCE$OLD" ]
then
  rm archives/CATALOGUE/.CATALOGUE.json.gz
  echo "$RDATA inchangé"
  exit
else
  NOW=$(date +%Y%m%dT%H%M%SZ)
  mv archives/CATALOGUE/.CATALOGUE.json.gz "archives/CATALOGUE/$NOW CATALOGUE.json.gz"
  ln -f -s "archives/CATALOGUE/$NOW CATALOGUE.json.gz" CATALOGUE.json.gz
fi

echo "$RDATA : $(zcat CATALOGUE.json.gz | jq .metadata[] -c | wc -l) jeux de données"
for DATASET in $(zcat CATALOGUE.json.gz | jq .metadata[] -c )
do
  ID=$(echo $DATASET | jq -r .title | sed 's/ /_/g')
  UPDATE=$(echo $DATASET | jq -r '."geonet:info".changeDate')
  TIMESTAMP=$(date -d "$UPDATE" +%Y%m%dT%H%M%SZ)
  TOUCH=$(date -d "$UPDATE" +%Y%m%d%H%M.%S)
  echo "meta $1 $ID $UPDATE"
  mkdir -p "archives/$ID/files"
  echo $DATASET | jq . -S > "archives/$ID/$TIMESTAMP $ID-meta.json"
  ln -f -s "archives/$ID/$TIMESTAMP $ID-meta.json" "$ID-meta.json"
  for FILE in $(echo $DATASET | jq -r '.link[]' | grep "$RDATA" | egrep -v $EXCLUSIONS)
  do
    echo $FILE
    URL=$(echo $FILE | awk -F "|" '{print $3}')
    FILENAME=$(echo $FILE | awk -F "|" '{print $1}')
    if [ "$(basename $URL)" = "all.json" ]
    then
      # on récupère le nombre d'enregistrements
      NB=$(curl -s --compressed -f "$(echo $URL | sed 's!/all.json!.json!')" | jq .nb_records)
      FILENAME="$(echo "$FILENAME" | sed 's!/all.json!!').shp.zip"
      URL="$(echo $URL | sed 's!/all.json!.shp!')?start=1&maxfeatures=$NB"
    fi
    if [ ! -f "archives/$ID/$TIMESTAMP $FILENAME" ] && [ ! -f "archives/$ID/$TIMESTAMP $FILENAME.gz" ]
    then
      echo "down $1 $ID $URL > $FILENAME"
      curl -s --compressed -f "$URL" > "archives/$ID/$TIMESTAMP $FILENAME" || rm "archives/$ID/$TIMESTAMP $FILENAME"
      if [ -f "archives/$ID/$TIMESTAMP $FILENAME" ]
      then
        touch -t $TOUCH "archives/$ID/$TIMESTAMP $FILENAME"
        ln -f -s "archives/$ID/$TIMESTAMP $FILENAME" "$ID - $FILENAME"
      fi
    fi
  done
done

