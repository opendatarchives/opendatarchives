#! /bin/bash

# Script d'archivage des données publiées sur un portail CKAN
# écrit par Christian Quest, sous licence WTFPL

EXCLUSIONS='name":"(base-adresse-nationale|openstreetmap-extraction|base-de-donnees-openstreetmap|base-sirene|codes-postaux|demandes-de-valeurs-foncieres|open-damir|pci-vecteur)'
# URL de base du portail à archiver
CKAN=$1
IFS=$'\n'

# création de la hiérarchie du dataset et de l'archive de son catalogue
mkdir -p "data/$CKAN/archives/CATALOGUE"
cd "data/$CKAN"

API="https://$CKAN/api"
[ -f .params ] && source .params

# liste des datasets
NOW=$(date +%Y%m%dT%H%M%SZ)
curl -c .cookies -L --compressed --insecure -sS "$API/3/action/current_package_list_with_resources?limit=10000" | jq .result -S > "archives/CATALOGUE/.CATALOGUE.json" || rm -f "archives/CATALOGUE/.CATALOGUE.json"
if [ ! -f "archives/CATALOGUE/.CATALOGUE.json" ]
then
  CATALOG=$(curl --compressed --insecure -sS "$API/3/action/package_list" | jq .result[] -r)
  for ID in $CATALOG
  do
    curl --compressed --insecure -sS "$API/3/action/package_show?id=$ID" | jq .result -c >> "archives/CATALOGUE/.CATALOGUE.json"
  done
  jq -s -S "archives/CATALOGUE/.CATALOGUE.json" | gzip -9 > "archives/CATALOGUE/$NOW CATALOGUE.json.gz"
  rm -f "archives/CATALOGUE/.CATALOGUE.json"
else
  mv "archives/CATALOGUE/.CATALOGUE.json" "archives/CATALOGUE/CATALOGUE.json"
  gzip -9 "archives/CATALOGUE/CATALOGUE.json"
  mv "archives/CATALOGUE/CATALOGUE.json.gz" "archives/CATALOGUE/$NOW CATALOGUE.json.gz"
fi

# les metadonnées ont-elles changé ?
JSON_OLD=$(zcat CATALOGUE.json.gz | jq -S .  | md5sum)
JSON_NEW=$(zcat "archives/CATALOGUE/$NOW CATALOGUE.json.gz" | jq -S . | md5sum)
if [ "$JSON_OLD" = "$JSON_NEW" ]
then
  rm "archives/CATALOGUE/$NOW CATALOGUE.json.gz"
else
  ln -f -s "archives/CATALOGUE/$NOW CATALOGUE.json.gz" CATALOGUE.json.gz
fi

echo "$CKAN :" $(zcat CATALOGUE.json.gz | jq .[] -c | egrep -v "$EXCLUSIONS" | wc -l) "jeux de données"
for DATASET in $(zcat CATALOGUE.json.gz | jq .[] -c | egrep -v "$EXCLUSIONS" )
do
  ID=$(echo $DATASET | jq -r .name)
  mkdir -p "archives/$ID"
  # metadonnées (triées pour diff) d'un dataset
  echo $DATASET | jq . -S > "archives/$ID/$ID-meta.json"
  DATE=$(jq -r .metadata_modified "archives/$ID/$ID-meta.json")
  META=$(date -d "$DATE" -u +%Y%m%dT%H%M%SZ)
  METAJSON="archives/$ID/$META $ID-meta.json"
  if [ -f "$METAJSON" ]
  then
    rm "archives/$ID/$ID-meta.json"
  else
    mv "archives/$ID/$ID-meta.json" "$METAJSON"
    touch "$METAJSON" -t $(date -d "$DATE" +"%Y%m%d%H%M.%S")
    ln -f -s "$METAJSON" "$ID-meta.json"
  fi

  # ressources d'un dataset
  for R in $(cat "$ID-meta.json" | jq .resources[] -c | sort -u)
  do
    URL=$(echo $R | jq -r .url)
    NAME=$(echo $R | jq -r .name)
    TIME=$(echo $R | jq -r .last_modified)
    DATE=$(date -d"$TIME" -u +"%Y%m%dT%H%M%SZ")
    TYPE=$(echo $R | jq -r .data_type)
    FILENAME=$(echo $URL | sed 's!^.*request=GetFeature.*typeName=\(.*\)&.*json.*$!\1.geojson!;s/:/_/g;s!^.*/exports/csv.*\?!'"$NAME"'!;s!^.*/explore/dataset/.*\?!'"$NAME"'!;s!^.*/!!;s!\?.*$!!')
    if [ ! "$TYPE" = "raw" ] && [ ! "$TYPE" = "null" ]
    then
      FOLDER="/attachments"
      mkdir -p "archives/$ID/attachments"
    else
      FOLDER=""
    fi

    # a-t-on déjà une archive du fichier ?
    if [ ! -f "archives/$ID$FOLDER/$DATE $FILENAME" ] && [ ! -f "archives/$ID$FOLDER/$DATE $FILENAME.gz" ]
    then
      echo "down $CKAN > $ID > $FOLDER $DATE $FILENAME"
      wget --no-check-certificate -q -c "$URL" -O "archives/$ID$FOLDER/.$FILENAME"
      # on n'avait pas de last_modified dans les metadonnées, on récupère celle du fichier téléchargé
      if [ "$TIME" = "null" ]
      then
        TIME=$(date -r "archives/$ID$FOLDER/.$FILENAME" -I)
        DATE=$(date -r "archives/$ID$FOLDER/.$FILENAME" +%Y%m%dT%H%M%SZ)
      fi
      mv "archives/$ID$FOLDER/.$FILENAME" "archives/$ID$FOLDER/$DATE $FILENAME"

      # peut-on compresser le fichier ?
      GZ=$(echo $FILENAME | egrep "\.(doc|docx|xls|xlsx|csv|json|geojson|xml|txt|rtf|kml|xml|gml)$")
      if [ ! "$GZ" = "" ]
      then
        echo "gzip $CKAN > $ID > $FOLDER $DATE $FILENAME"
        pigz -f -9 "archives/$ID$FOLDER/$DATE $FILENAME"
        FILENAME="$FILENAME.gz"
      fi
      # on remet la date de modification indiquée en metadonnées
      touch "archives/$ID$FOLDER/$DATE $FILENAME" -t $(date -d "$TIME" +"%Y%m%d%H%M.%S")
      if [ "$FOLDER" = "" ]
      then
        ln -f -s "archives/$ID/$DATE $FILENAME" "$ID _ $FILENAME"
      fi
    fi
  done

done
find . -type f -size 0c -delete

echo "$CKAN : fin"
