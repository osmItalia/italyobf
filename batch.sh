#!/bin/bash

# Questo script utilizza Splitter e OsmAndCreator per suddividere
# un file .osm.pbf in molte sottomappe,
# per ignuna di esse crea una mappa .obf navigabile con OsmAnd
# e un file unico per la ricerca degli indirizzi.

# Autore: Stefano Droghetti, Luca Delucchi
# Licenza: GPL

# Versione: vedi file Readme


URL="http://download.geofabrik.de/openstreetmap/europe/"
FNAME="italy-latest.osm.pbf"
COUNTRY="Italia"
XMS=1000M
XMX=8000M

usage()
{
  echo "Utilizzo: `basename $0` opzioni 

Opzioni:
    -f          non scarica il file ${FNAME} ma lo prende
                dalla cartella in cui si trova `basename $0`
    -h          visualizza questa schermata
"
}

download()
{

    echo "Downloading ${file_name} file..."

    $DTOOL ${URL}${FNAME}

}


run(){
    echo "Splitting original map"
    java -Xms${XMS} -Xmx${XMX} -jar splitter/splitter.jar --max-areas=4096 --max-nodes=3000000 --wanted-admin-level=8 --geonames-file=cities15000.txt $FNAME
    mv 6*.osm.pbf osmand-pbf

    echo "Creating OBF maps"
    cd OsmAndMapCreator
    java -Djava.util.logging.config.file=logging.properties -Xms${XMS} -Xmx${XMX} -cp "./OsmAndMapCreator.jar:lib/OsmAnd-core.jar:./lib/*.jar" net.osmand.data.index.IndexBatchCreator ../batch-normale.xml

    echo "Maps union"
    java -Djava.util.logging.config.file=logging.properties -Xms${XMS} -Xmx${XMX} -cp "./OsmAndMapCreator.jar:lib/OsmAnd-core.jar:./lib/*.jar" net.osmand.MainUtilities merge-index ../osmand-obf/$COUNTRY.obf --address ../osmand-obf/${1}*.obf

    cd ..

    rm -f osmand-obf/*.log osmand-obf/6* osmand-gen/* osmand-pbf/* tmp/*
}

#print help
if [ "$#" = "--help" ] ; then
    usage
    exit
fi


if which aria2c >/dev/null; then
    DTOOL=aria2c
elif which wget >/dev/null; then
    DTOOL=wget
elif which curl >/dev/null; then
    DTOOL=curl
else
    echo "'aria2c', 'wget' o 'curl' è richiesto, installare uno dei due per far continuare lo script"
    exit 1

fi

DOWN=true

while getopts "fh" Opzione
do
    case $Opzione in
        #doesn't download file
        f ) DOWN=false;;
        #print help
        h ) usage; exit;;
    esac
done

#scarica i dati dell'italia, per altri stati basta cambiare il path
if [ "$DOWN" = true ] ; then
    download
fi

run
