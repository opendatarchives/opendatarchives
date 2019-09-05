#! /bin/bash

DCAT=$1
IFS=$'\n'

# décodage URL
urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

echo "$DCAT: $(date -Iseconds)"

FORMAT_EXCLUDE="(OGC|REST|Web)"
if [[ $DCAT =~ arcgis ]]
then
  FORMAT_EXCLUDE="(OGC|REST|Web|KML|Shapefile|ArcGIS)"
fi

mkdir -p data/$1/archives/CATALOGUE
cd data/$1

NOW=$(date +%Y%m%dT%H%M%SZ)
curl --compressed --insecure -L -sS https://$DCAT/data.json | jq . -S | gzip -9 > archives/CATALOGUE/.CATALOGUE.json.gz
NEW=$(zcat archives/CATALOGUE/.CATALOGUE.json.gz | jq . -S | md5sum)
OLD=$(zcat CATALOGUE.json.gz | jq . -S | md5sum)
if [ "$OLD" = "$NEW" ]
then
  rm archives/CATALOGUE/.CATALOGUE.json.gz
else
  mv archives/CATALOGUE/.CATALOGUE.json.gz "archives/CATALOGUE/$NOW CATALOGUE.json.gz"
  ln -f -s "archives/CATALOGUE/$NOW CATALOGUE.json.gz" CATALOGUE.json.gz
fi

echo "$DCAT: $(zcat CATALOGUE.json.gz | jq .dataset[] -c | wc -l) jeux de données"
for DATASET in $(zcat CATALOGUE.json.gz | jq .dataset[] -c)
do
  ID=$(echo $DATASET | jq -r .title | sed 's/ /_/g;s!/!_!g')
  OLD=$(echo $DATASET  | jq . -S | md5sum)
  NEW=$(jq . -S "$ID-meta.json" | md5sum)
  if [ ! "$OLD" = "$NEW" ]
  then
    TIME=$(echo $DATASET | jq -r .modified)
    DATE=$(date -d "$TIME" +%Y%m%dT%H%M%SZ)

    mkdir -p "archives/$ID"
    echo "meta $DCAT $ID $DATE"
    echo $DATASET | jq . -S > "archives/$ID/$DATE $ID-meta.json"
    ln -f -s "archives/$ID/$DATE $ID-meta.json" "$ID-meta.json"

    for RSRC in $(echo $DATASET | jq -c .distribution[] | egrep -v $FORMAT_EXCLUDE)
    do
      URL=$(echo $RSRC | jq -r .accessURL)
      if [ "$URL" = "null" ]
      then
        URL=$(echo $RSRC | jq -r .downloadURL)
      fi
      FILENAME=$(curl -I -L -s "$URL" | grep ^Content-disposition | sed 's/^.*filename=//;s/.$//' | tail -n 1)
      FILENAME=$(urldecode "$FILENAME")
      if [ ! -f "archives/$ID/$DATE $FILENAME" ] && [ ! -f "archives/$ID/$DATE $FILENAME.gz" ]
      then
        echo "down $DCAT $ID $URL > $DATE $FILENAME"
        wget -q -N -c "$URL" -O "archives/$ID/$DATE $FILENAME" || rm -f "archives/$ID/$DATE $FILENAME"

        if [ -f "archives/$ID/$DATE $FILENAME" ]
        then
          # peut-on compresser le fichier ?
          GZ=$(echo $FILENAME | egrep "\.(doc|docx|xls|xlsx|csv|json|geojson|xml|txt|rtf|kml|xml|gml)$")
          if [ ! "$GZ" = "" ]
          then
            echo "gzip $DCAT > $ID > $FOLDER $DATE $FILENAME"
            pigz -f -9 "archives/$ID$FOLDER/$DATE $FILENAME"
            FILENAME="$FILENAME.gz"
          fi

          ln -f -s "archives/$ID/$DATE $FILENAME" "$FILENAME"
        fi
      fi
    done
  fi
done
echo "$DCAT: $(date -Iseconds) fin"

