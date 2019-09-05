#! /bin/bash

IFS=$'\n'

echo csv
MV=$(find $1 -type f -name *_20*T*+00:00*.csv.gz)
for F in $MV
do
  DIR=$(dirname $F)
  FILE=$(basename $F)
  NEW=$(echo $FILE | sed 's/^\(.*\)_\(20[0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)T\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).*csv.gz/\2\3\4T\5\6\7Z \1.csv.gz/')
  echo "$FILE -> $NEW"
  mv "$DIR/$FILE" "$DIR/$NEW"
done

MV=$(find $1 -type f -name *20*T*Z.csv.gz)
for F in $MV
do
  DIR=$(dirname $F)
  FILE=$(basename $F)
  NEW=$(echo $FILE | sed 's/^\(.*\)\(20[0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z\).csv.gz/\2 \1.csv.gz/')
  echo "$FILE -> $NEW"
  mv "$DIR/$FILE" "$DIR/$NEW"
done

echo geojson
MV=$(find $1 -type f -name *_20*T*+00:00*.geojson.gz)
for F in $MV
do
  DIR=$(dirname $F)
  FILE=$(basename $F)
  NEW=$(echo $FILE | sed 's/^\(.*\)_\(20[0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)T\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).*geojson.gz/\2\3\4T\5\6\7Z \1.geojson.gz/')
  echo "$FILE -> $NEW"
  mv "$DIR/$FILE" "$DIR/$NEW"
done

MV=$(find $1 -type f -name *20*T*Z.geojson.gz)
for F in $MV
do
  DIR=$(dirname $F)
  FILE=$(basename $F)
  NEW=$(echo $FILE | sed 's/^\(.*\)\(20[0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z\).geojson.gz/\2 \1.geojson.gz/')
  echo "$FILE -> $NEW"
  mv "$DIR/$FILE" "$DIR/$NEW"
done

echo metadonnées
MV=$(find $1 -type f -name *_20*T*+00:00-meta.json)
for F in $MV
do
  DIR=$(dirname $F)
  FILE=$(basename $F)
  NEW=$(echo $FILE | sed 's/^\(.*\)_\(20[0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\)T\([0-9][0-9]\).\([0-9][0-9]\).\([0-9][0-9]\).*meta.json/\2\3\4T\5\6\7Z \1-meta.json/')
  echo "$FILE -> $NEW"
  mv "$DIR/$FILE" "$DIR/$NEW"
done

MV=$(find $1 -type f -name *20*T*Z-meta.json)
for F in $MV
do
  DIR=$(dirname $F)
  FILE=$(basename $F)
  NEW=$(echo $FILE | sed 's/^\(.*\)\(20[0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z\)\-meta.json/\2 \1-meta.json/')
  echo "$FILE -> $NEW"
  mv "$DIR/$FILE" "$DIR/$NEW"
done

cd $1
ln -f -s "archives/CATALOGUE/$(ls -1 archives/CATALOGUE | sort | tail -n 1)" CATALOGUE.csv.gz
