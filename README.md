# OSM map tools
Tools to download, process and copy osm maps, altitute lines and hillshades. 

# Usage
The following scripts can be used

* Downloading (download_regions.R): downloads osm files to a local directory
* Copying (copy_regions.R): copies files from local to remote directory. Typically used to copy the files to an SD card

Both scripts by default read in the file `regions.txt`, which specifies which regions are downloaded
or copied. Also by default, the scripts download map files, altitude lines and hillshades for
those regions.

## Command line arguments

* --all-regions: download all files instead of the ones in regions.txt
* --no-maps: do not download maps files
* --no-contours: do not download altitude files
* --no-hillshade: do not download hillshade files

* --local-dir <>: the local directory to which to download the files
* --target-dir <> (copy_regions only, optional): the directory to which to copy the files from the local dir. Defaults to /Android/data/net.osmand/files

## After the run
After copying the files to your SD card, install the free OSMand app and set the location of the
files in its settings. This location requires to prefix the folder with the location of the SD card.
The prefix is typically in the form `/storage/NNNN-NNNN/`, where each N is a digit. To find the values
for N, take a picture with the camera and identify its location in Gallery properties or use a 
proper file browser.



