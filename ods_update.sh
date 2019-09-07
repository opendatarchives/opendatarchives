#! /bin/bash

# Archiveur de portail opendata OpenDataSoft
# script écrit par Christian Quest, sous licence WTFPL

# liste des jeux de données à ne pas archiver (SPD, etc)
EXCLUSIONS="(base.sirene|^registre.parcellaire.graphique|^geofla|base.adresse.nationale|^previsions-meteo-france-metropole|repertoire-national-des-elus|synop|prevision.*arome)"
# force les mises à jour (laisser vide pour le mode normal)
FORCE=""

# domaine du portail OpenDataSoft à archiver
ODS=$(echo $1 | sed 's!/!!g')

# heure actuelle (ISO)
NOW=$(date +%Y%m%dT%H%M%SZ)

WGET='wget -nc '
GZIP='pigz -9 --rsyncable '
CURL='curl --compressed --insecure -sS '

#IFS=$'\n'
# dossier où seront archivées les données
mkdir -p $ODS/archives/CATALOGUE
cd $ODS

# récupération du catalogue du portail

$CURL  "https://$ODS/explore/download/" | $GZIP > archives/CATALOGUE/.CATALOGUE.csv.gz

# on ne fait le traitement que si il y a eu un changement
LAST_PREV=$(zcat CATALOGUE.csv.gz | csvcut -d ';' -z 500000 -c modified,data_processed,metadata_processed | sed 's/,/\n/g;' | grep '^20' | sort | tail -n 1)
LAST_NEW=$(zcat "archives/CATALOGUE/.CATALOGUE.csv.gz" | csvcut -d ';' -z 500000 -c modified,data_processed,metadata_processed | sed 's/,/\n/g;' | grep '^20' | sort | tail -n 1)
if [ "$LAST_PREV" = "$FORCE$LAST_NEW" ]
then
  echo "$ODS: inchangé"
  rm archives/CATALOGUE/.CATALOGUE.csv.gz
  exit
fi
mv archives/CATALOGUE/.CATALOGUE.csv.gz "archives/CATALOGUE/$NOW CATALOGUE.csv.gz"
ln -f -s "archives/CATALOGUE/$NOW CATALOGUE.csv.gz" CATALOGUE.csv.gz

# liste des ID et date de dernier traitement (mise à jour) des données
RSRC=$(zcat CATALOGUE.csv.gz | egrep -v "$EXCLUSIONS" | csvcut -c datasetid,data_processed,metadata_processed -d ';' -z 500000 - | grep ",2.*:00$" | sed 's/ /T/g' | sort)
echo "$ODS: $(echo $RSRC | sed 's/ /\n/g' | wc -l) jeux de données"
for R in $RSRC
do
  read ID TIMESTAMP META <<< $( echo ${R} | awk -F"," '{print $1 " " $2 " " $3}' )
  OLDTIMESTAMP="_$TIMESTAMP"
  OLDMETA="_$META"
  TOUCH=$(date -d $(echo "$TIMESTAMP" +%Y%m%d%H%M.%S) || date -u +%Y%m%d%H%M.%S)
  TIMESTAMP=$(date -d "$TIMESTAMP" -u +%Y%m%dT%H%M%SZ || date -u +%Y%m%dT%H%M%SZ)
  META=$(date -d "$META" -u +%Y%m%dT%H%M%SZ || date -u +%Y%m%dT%H%M%SZ)

  mkdir -p archives/$ID

  # renommage OLDTIMESTAMP > TIMESTAMP
  if [ -f "archives/$ID/$ID$OLDTIMESTAMP.csv.gz" ]
  then
    echo "mv archives/$ID/$ID$OLDTIMESTAMP.csv.gz -> archives/$ID/$TIMESTAMP $ID.csv.gz"
    mv "archives/$ID/$ID$OLDTIMESTAMP.csv.gz" "archives/$ID/$TIMESTAMP $ID.csv.gz"
    ln -f -s "archives/$ID/$TIMESTAMP $ID.csv.gz" "$ID.csv.gz"
    touch -m -t $TOUCH "$ID.csv.gz"
    touch -m -t $TOUCH "archives/$ID/$TIMESTAMP $ID.csv.gz"
  fi
  if [ -f "archives/$ID/$ID$OLDTIMESTAMP.geojson.gz" ]
  then
    echo "mv archives/$ID/$ID$OLDTIMESTAMP.geojson.gz -> archives/$ID/$TIMESTAMP $ID.geojson.gz"
    mv "archives/$ID/$ID$OLDTIMESTAMP.geojson.gz" "archives/$ID/$TIMESTAMP $ID.geojson.gz"
    ln -f -s "archives/$ID/$TIMESTAMP $ID.geojson.gz" "$ID.geojson.gz"
    touch -m -t $TOUCH "$ID.geojson.gz"
    touch -m -t $TOUCH "archives/$ID/$TIMESTAMP $ID.geojson.gz"
  fi
  if [ -f "archives/$ID/$ID $TIMESTAMP.csv.gz" ]
  then
    echo "mv archives/$ID/$ID $TIMESTAMP.csv.gz -> archives/$ID/$TIMESTAMP $ID.csv.gz"
    mv "archives/$ID/$ID $TIMESTAMP.csv.gz" "archives/$ID/$TIMESTAMP $ID.csv.gz"
    ln -f -s "archives/$ID/$TIMESTAMP $ID.csv.gz" "$ID.csv.gz"
    touch -m -t $TOUCH "$ID.csv.gz"
    touch -m -t $TOUCH "archives/$ID/$TIMESTAMP $ID.csv.gz"
  fi
  if [ -f "archives/$ID/$ID $TIMESTAMP.geojson.gz" ]
  then
    echo "mv archives/$ID/$ID $TIMESTAMP.geojson.gz -> archives/$ID/$TIMESTAMP $ID.geojson.gz"
    mv "archives/$ID/$ID $TIMESTAMP.geojson.gz" "archives/$ID/$TIMESTAMP $ID.geojson.gz"
    ln -f -s "archives/$ID/$TIMESTAMP $ID.geojson.gz" "$ID.geojson.gz"
    touch -m -t $TOUCH "$ID.geojson.gz"
    touch -m -t $TOUCH "archives/$ID/$TIMESTAMP $ID.geojson.gz"
  fi
  if [ -f "archives/$ID/$ID$TIMESTAMP.csv.gz" ]
  then
    echo "mv archives/$ID/$ID$TIMESTAMP.csv.gz -> archives/$ID/$TIMESTAMP $ID.csv.gz"
    mv "archives/$ID/$ID$TIMESTAMP.csv.gz" "archives/$ID/$TIMESTAMP $ID.csv.gz"
    ln -f -s "archives/$ID/$TIMESTAMP $ID.csv.gz" "$ID.csv.gz"
    touch -m -t $TOUCH "$ID.csv.gz"
    touch -m -t $TOUCH "archives/$ID/$TIMESTAMP $ID.csv.gz"
  fi
  if [ -f "archives/$ID/$ID$TIMESTAMP.geojson.gz" ]
  then
    echo "mv archives/$ID/$ID$TIMESTAMP.geojson.gz -> archives/$ID/$TIMESTAMP $ID.geojson.gz"
    mv "archives/$ID/$ID$TIMESTAMP.geojson.gz" "archives/$ID/$TIMESTAMP $ID.geojson.gz"
    ln -f -s "archives/$ID/$TIMESTAMP $ID.geojson.gz" "$ID.geojson.gz"
    touch -m -t $TOUCH "$ID.geojson.gz"
    touch -m -t $TOUCH "archives/$ID/$TIMESTAMP $ID.geojson.gz"
  fi
  if [ -f "archives/$ID/$ID$OLDTIMESTAMP-meta.json" ]
  then
    echo "mv archives/$ID/$ID$OLDTIMESTAMP-meta.json -> archives/$ID/$ID $TIMESTAMP-meta.json"
    mv "archives/$ID/$ID$OLDTIMESTAMP-meta.json" "archives/$ID/$ID $TIMESTAMP-meta.json"
    ln -f -s "archives/$ID/$ID $TIMESTAMP-meta.json" "$ID-meta.json"
    touch -m -t $TOUCH "$ID-meta.json"
    touch -m -t $TOUCH "archives/$ID/$ID $TIMESTAMP-meta.json"
  fi
  # renommage des metadonnées
  if [ -f "archives/$ID/$ID$OLDMETA-meta.json" ]
  then
    echo "mv archives/$ID/$ID$OLDMETA-meta.json -> archives/$ID/$META $ID-meta.json"
    mv "archives/$ID/$ID$OLDMETA-meta.json" "archives/$ID/$META $ID-meta.json"
    ln -f -s "archives/$ID/$META $ID-meta.json" "$ID-meta.json"
    touch -m -t $TOUCH "$ID-meta.json"
    touch -m -t $TOUCH "archives/$ID/$META $ID-meta.json"
  fi
  if [ -f "archives/$ID/$ID$META-meta.json" ]
  then
    echo "mv archives/$ID/$ID$META-meta.json -> archives/$ID/$META $ID-meta.json"
    mv "archives/$ID/$ID$META-meta.json" "archives/$ID/$META $ID-meta.json"
    ln -f -s "archives/$ID/$META $ID-meta.json" "$ID-meta.json"
    touch -m -t $TOUCH "$ID-meta.json"
    touch -m -t $TOUCH "archives/$ID/$META $ID-meta.json"
  fi
  if [ -f "archives/$ID/$ID $META-meta.json" ]
  then
    echo "mv archives/$ID/$ID $META-meta.json -> archives/$ID/$META $ID-meta.json"
    mv "archives/$ID/$ID $META-meta.json" "archives/$ID/$META $ID-meta.json"
    ln -f -s "archives/$ID/$META $ID-meta.json" "$ID-meta.json"
    touch -m -t $TOUCH "$ID-meta.json"
    touch -m -t $TOUCH "archives/$ID/$META $ID-meta.json"
  fi
  
  # compression des fichiers qui avaient été chargés sans compression

  if [ -f "archives/$ID/$TIMESTAMP $ID.csv" ]
  then
    echo "gzip $ID"
    $GZIP "archives/$ID/$TIMESTAMP $ID.csv"
    rm "$ID.csv"
    # mise à jour du lien symbolique
    ln -f -s "archives/$ID/$TIMESTAMP $ID.csv.gz" "$ID.csv.gz"
    touch -m -t $TOUCH "$ID.csv.gz"
    touch -m -t $TOUCH "archives/$ID/$TIMESTAMP $ID.csv.gz"
  fi

  # archivage des metadonnées JSON du jeu de données
  if [ ! -f "archives/$ID/$META $ID-meta.json" ]
  then

    # json trié pour permettre les diff
    $CURL -f "https://$ODS/api/datasets/1.0/$ID/" | jq . -S > "archives/$ID/$META $ID-meta.json"

    # contrôle de changement réel des méta-données et pas que de metadata_processed
    META_OLD=$(jq -S . "$ID-meta.json" | grep -v 'metadata_processed' | md5sum)
    META_NEW=$(jq -S . "archives/$ID/$META $ID-meta.json" | grep -v 'metadata_processed' | md5sum)
    if [ "$META_OLD" = "$FORCE$META_NEW" ]
    then
      echo "meta $ODS $ID $META : inchangé"
      rm "archives/$ID/$META $ID-meta.json"
    else
      echo "meta $ODS $ID $META : nouvelles"
      ln -f -s "archives/$ID/$META $ID-meta.json" "$ID-meta.json"
    fi
  fi

  # archivage du contenu du jeu de données au format CSV
  if [ ! -f "archives/$ID/$TIMESTAMP $ID.csv.gz" ]
  then
    echo "down $ODS $ID $TIMESTAMP"
    # download avec timestamp (pour ne charger que les jeux de données modifiés)
    $CURL -f "https://$ODS/explore/dataset/$ID/download/?format=csv&timezone=Europe/Berlin&use_labels_for_header=true" | $GZIP > "archives/$ID/$TIMESTAMP $ID.csv.gz"
  fi

  # mise à jour du lien symbolique
  if [ -f "archives/$ID/$TIMESTAMP $ID.csv.gz" ]
  then
    # lien symbolique existant et pointant vers une autre version des données ?
    if [ -f "$ID.csv.gz" ] && [ ! "$(readlink "$ID.csv.gz")" = "archives/$ID/$TIMESTAMP $ID.csv.gz" ]
    then
      # le contenu a-t-il changé ?
      # on compare le nombre de lignes du CSV
      if [ ! $(zcat "$ID.csv.gz" | wc -l) = $(zcat "archives/$ID/$TIMESTAMP $ID.csv.gz" | wc -l) ]
      then
        # puis son contenu complet
        OLD=$(zcat "$ID.csv.gz" | sort | md5sum)
        NEW=$(zcat "archives/$ID/$TIMESTAMP $ID.csv.gz" | sort | md5sum)
        if [ "$OLD" = "$NEW" ]
        then
          echo "same $ODS $ID $TIMESTAMP csv"
          rm "archives/$ID/$TIMESTAMP $ID.csv.gz"
        fi
      fi
    fi

    if [ -f "archives/$ID/$TIMESTAMP $ID.csv.gz" ]
    then
      # création ou mise à jour du lien symbolique et des timestamp des fichiers
      ln -f -s "archives/$ID/$TIMESTAMP $ID.csv.gz" "$ID.csv.gz"
      touch -m -t $TOUCH "$ID.csv.gz"
      touch -m -t $TOUCH "archives/$ID/$TIMESTAMP $ID.csv.gz"
    else
      echo "fail $ODS $ID $TIMESTAMP csv"
    fi
  fi

  # données géographiques ? on archive aussi au format geojson
  GEO=$(jq . "$ID-meta.json" | grep -o '"geo"' )
  if [ "$GEO" = "\"geo\"" ]
  then
    if [ ! -f "archives/$ID/$TIMESTAMP $ID.geojson.gz" ]
    then
      echo "geo $ODS $ID $TIMESTAMP"
      # download avec timestamp (pour ne charger que les jeux de données modifiés)
      $CURL -f "https://$ODS/explore/dataset/$ID/download/?format=geojson&timezone=Europe/Berlin&use_labels_for_header=true" | $GZIP > "archives/$ID/$TIMESTAMP $ID.geojson.gz"

    fi
    if [ -f "archives/$ID/$TIMESTAMP $ID.geojson.gz" ]
    then
      # lien symbolique existant et pointant vers une autre version des données ?
      if [ -f "$ID.geojson.gz" ] && [ ! "$(readlink "$ID.geojson.gz")" = "archives/$ID/$TIMESTAMP $ID.geojson.gz" ]
      then
        OLD=$(zcat "$ID.geojson.gz" | jq . -S | md5sum)
        NEW=$(zcat "archives/$ID/$TIMESTAMP $ID.geojson.gz" | jq . -S | md5sum)
        # les données sont identiques, on supprime la "nouvelle version"
        if [ "$OLD" = "$NEW" ]
        then
          echo "same $ODS $ID $TIMESTAMP geojson"
          rm "archives/$ID/$TIMESTAMP $ID.geojson.gz"
        fi
      fi
      if [ -f "archives/$ID/$TIMESTAMP $ID.geojson.gz" ]
      then
        # création ou mise à jour du lien symbolique et des timestamp des fichiers
        ln -f -s "archives/$ID/$TIMESTAMP $ID.geojson.gz" "$ID.geojson.gz"
        touch -m -t $TOUCH "$ID.geojson.gz"
        touch -m -t $TOUCH "archives/$ID/$TIMESTAMP $ID.geojson.gz"
      fi
    else
      echo "fail $ODS $ID $TIMESTAMP geojson"
    fi
  fi

  # traitement des pièces jointes
  FILES=$(jq  '.attachments[]|{url:.url,id:.id}' "$ID-meta.json" -c)
  for FILE in $FILES
  do
    mkdir -p "archives/$ID/attachments"
    FILENAME=$(echo $FILE | jq -r .url | sed 's!odsfile://!!')
    URL=$(echo $FILE | jq -r .id)
    if [ ! -f "archives/$ID/attachments/$FILENAME" ]
    then
      echo "file $ODS > $ID > $FILENAME"
      $WGET -q "https://$ODS/api/datasets/1.0/$ID/attachments/$URL/" -O "archives/$ID/attachments/$FILENAME" || rm "archives/$ID/attachments/$FILENAME"
    fi
  done

  # on supprime les fichiers vides résiduels
  find "archives/$ID" -size 0 -delete
  find . -name "$ID*" -size 0 -delete
done
cd - > /dev/null
echo "$ODS: fin"

# renommage global des fichiers
./ods_rename.sh $ODS
