if which aria2c >/dev/null; then
    DOWN=aria2c
else
    DOWN=wget
fi

# download splitter
SP_VER=435
$DOWN -c http://www.mkgmap.org.uk/download/splitter-r${SP_VER}.zip
unzip splitter-r${SP_VER}.zip
mv splitter-r${SP_VER} splitter
# download cities15000
$DOWN -c http://download.geonames.org/export/dump/cities15000.zip
unzip cities15000.zip
# download OsmAndCreator
$DOWN -c http://download.osmand.net/latest-night-build/OsmAndMapCreator-main.zip
mkdir OsmAndMapCreator
unzip OsmAndMapCreator-main.zip -d OsmAndMapCreator/
# remove unused files
rm -f *.zip
# create new folder
if [ ! -d osmand-gen ] ; then
  mkdir osmand-gen osmand-obf osmand-pbf
fi
