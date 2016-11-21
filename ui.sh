#!/bin/bash

# Questo script utilizza Splitter e OsmAndCreator per suddividere
# un file .osm.pbf o un file .osm.bz2 in molte sottomappe,
# per ignuna di esse crea una mappa .obf navigabile con OsmAnd
# e un file unico per la ricerca degli indirizzi.

# Autore: Stefano Droghetti
# Licenza: GPL

# Versione: vedi file Readme





# Schermata di presentazione

zenity --info --title="Osmux" --text="Questo script converte una mappa\nOSM dal formato .osm.bz2 o .osm.pbf\nnel formato obf per OsmAnd."

# Chiedo quanta memoria minima deve avere (richiesto per Java)

MINIMO=`zenity --entry --title="Osmux" --entry-text="64" --text="Memoria minima da utilizzare in MB (default=64MB)"`

# Se non viene scritto nulla, si prende il default

if [ "$MINIMO" = "" ]; then
	MINIMO=64
fi

# Se non è un nmero, esce

if ! [ "$MINIMO" -eq "$MINIMO" ] 2> /dev/null
then
    zenity --info --title="Osmux" --text="Solo numeri interi!\nBye bye!"
    exit
fi

echo $MINIMO

# Stessa cosa di prima, per la memoria massima

MASSIMO=`zenity --entry --title="Osmux" --entry-text="2000" --text="Memoria massima da utilizzare in MB (default=2000MB)"`

if [ "$MASSIMO" = "" ]; then
	MASSIMO=2000
fi

if ! [ "$MASSIMO" -eq "$MASSIMO" ] 2> /dev/null
then
    zenity --info --title="Osmux" --text="Solo numeri interi!\nBye bye!"
    exit
fi

echo $MASSIMO

# Chiede dov'è il file OSM da convertire 

DIRFILE=`zenity --file-selection --title="Seleziona il file .osm.bz2 o osm.pbf da convertire"`

if [ "$DIRFILE" = "" ]; then
	zenity --info --title="Osmux" --text="Bye bye!"
	exit
fi

# Controlla che il file sia di tipo consenstito e mette
# nome file, cartella, estensione eccetera in varie variabili

ESTENSIONE=".osm.bz2"
ESTENSION2=".osm.pbf"
NOMEFILE=`basename $DIRFILE`
BASEFILE=${NOMEFILE%%$ESTENSIONE}
if [ $BASEFILE = $NOMEFILE ]; then
	BASEFILE=${NOMEFILE%%$ESTENSION2}
fi
ESTENS=${NOMEFILE##$BASEFILE}
echo "DIRFILE = $DIRFILE"
echo "NOMEFILE = $NOMEFILE"
echo "BASEFILE = $BASEFILE"
echo "ESTENS = $ESTENS"
if [ "$ESTENS" != "$ESTENSIONE" -a "$ESTENS" != "$ESTENSION2" ]; then
	zenity --error --title="Errore" --text="Sono ammessi soltanto file di tipo $ESTENSIONE o $ESTENSION2"
	exit
fi


# Cancella file inutili

cd osmand-gen
rm *.*
cd ..

cd osmand-pbf
rm *.*
cd ..

cd osmand-obf
rm *.*
cd ..

rm *.log

# Fa partire il cronometro

START=$(date +%s.%N)

# Usa splitter per suddividere le mappe

echo -e "\n\n\n\nDivisione della mappa in piccole sottomappe...\n\n\n\n\n"

java -Xms${MINIMO}M -Xmx${MASSIMO}M -jar ../splitter*/splitter.jar --max-areas=4096 --max-nodes=3000000 --wanted-admin-level=8 --geonames-file=../cities15000.txt $DIRFILE
mv *.osm.pbf ../osmand-pbf
cd ..

# Converte ognuna della mappe in .obf

echo -e "\n\n\n\nCreazione delle mappe .obf...\n\n\n\n\n"

cd OsmAndMapCreator
java -Djava.util.logging.config.file=logging.properties -Xms${MINIMO}M -Xmx${MASSIMO}M -cp "./OsmAndMapCreator.jar:lib/OsmAnd-core.jar:./lib/*.jar" net.osmand.data.index.IndexBatchCreator ../batch-normale.xml

# Usa le mappe .obf create per creare un unico file di indirizzi

echo -e "\n\n\n\nUnione delle mappe in un unico file...\n\n\n\n\n"

java -Djava.util.logging.config.file=logging.properties -Xms${MINIMO}M -Xmx${MASSIMO}M -cp "./OsmAndMapCreator.jar:lib/OsmAnd-core.jar:./lib/*.jar" net.osmand.MainUtilities merge-index ../osmand-obf/${BASEFILE}.obf --address ../osmand-obf/${1}*.obf

cd ..

# Cancella i file inutili e rinomina le mappe.

cd osmand-obf
rm *.log
rm 6324*.*
cd ..

cd osmand-gen
rm *.*
cd ..

cd osmand-pbf
rm *.*
cd ..

# Ferma il cronometro e calcola quanto ci ha messo

END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
TEMPO=`date -d@$DIFF -u +%H:%M:%S`

# Schermata finale con apertura cartella con i file creati

zenity --info --title="Osmux" --text="Si aprira' ora una finestra\ncontenente il file da copiare\nnella cartella di OsmAnd sullo smartphone.\n\nMappa creata in $TEMPO"

xdg-open osmand-obf

echo "Bye bye!"
exit
