# OpenDatArchives

Ce projet a pour but de conserver une archive historisée des données #Opendata disponibles en France

L'objectif est de conserver les versions successives du contenu des jeux de données et des méta-données les décrivant.

Certains jeux de données peuvent être "repackagés" dans un autre format et/ou recompressés pour faciliter la réutilisation et/ou optimiser stockage et téléchargement.


## Source et licence

Le producteur des données, leur source, dates de publication/mise à jour ainsi que la licence sous laquelle elles sont publiées figure dans les fichiers de metadonnées.

En téléchargeant des données sur ce site, vous vous engagez de-facto à respecter la licence sous laquelle ils sont publiés et indiquée dans ces métadonnées.


## Organisation

Les données sont organisées en plusieurs niveaux:
- domaine du portail opendata, ex: opendata.paris.fr
  - dernières version du contenu des jeux de données et méta-données
  - archives
    - nom d'un jeu de données, ex: abri-voyageurs-ecrans-tactiles-connectes
      - versions successives du contenu du jeu de données et des méta-données (date en ISO compact en préfixe)

Exemple (pour un jeu de données):
- opendata.paris.fr
  - abri-voyageurs-ecrans-tactiles-connectes.csv.gz
  - abri-voyageurs-ecrans-tactiles-connectes-meta.json
  - archives
    - 20160413T102500Z abri-voyageurs-ecrans-tactiles-connectes.csv.gz
    - 20170513T145703Z abri-voyageurs-ecrans-tactiles-connectes.csv.gz
    - 20160413T104000Z abri-voyageurs-ecrans-tactiles-connectes-meta.json


## Pourquoi / Comment ?

Un article à lire sur https://medium.com/@cq94/opendatarchives-7f1707fb29aa


## Contact / Questions ?

github (code et issues): https://github.com/opendatarchives/opendatarchives

Rester informé via twitter: @opendatarchives  -  https://twitter.com/opendatarchives 

sinon...

Christian Quest
email:    cquest@cquest.org
mastodon: @cquest@amicale.net  -  https://amicale.net/@cquest
twitter:  @cq94  -  https://twitter.com/cq94 
