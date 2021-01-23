# OSM map tools
Tools to download, process and copy openstreetmap map files, altitute lines and hillshades.  
For information on the map source, visit https://www.openstreetmap.org/

# Requirements
An installation of R (with Rscript executable) >3.6 and the following installed packages:

* rvest
* dplyr
* purrr
* stringr
* fs
* optparse

# Usage
The following scripts can be used

* Downloading (download_regions.R): downloads osm files to a local directory
* Copying (copy_regions.R): copies files from local to remote directory. Typically used to copy the files to an SD card

## Default behaviour
Take into account the following default behaviour of the scripts:

* Both scripts by default read in a regions file (default: regions.txt in current working
dir), which specifies which regions are downloaded or copied. 
* The scripts download map files, altitude lines and hillshades for those regions. 
* If any of the files already exists, the files are not overwritten. Delete files beforehand
if you want to download/copy the latest versions.
* The 3 file types are downloaded and copied into the same folder structure as the OsmAnd app uses. This way, once the location of the root folder is set (folder `files`) in the app, all 3 file types should be automatically found and rendered.

The first 2 default behaviours can be overridden via the command line arguments.

## Command line arguments
Run `Rscript download_regions.R -h` to get an overview of commandline options

## Example usage
To download all western european maps, contour lines, and hillshades and copy the ones from the Benelux to `~/osm_maps_copy`, use the provided example files in the data folder and run from this repo's root:
`Rscript download_regions.R -r data/western_europe_regions.txt && Rscript copy_regions.R -r data/benelux_regions.txt -d ~/osm_maps_copy`. This uses the default `~/osm_downloads` local directory as intermediate.

## regions file
The regions file contains one region that should be processed on each line. When a region occurs in the filename based on regex matching, that file is processed. The filenames for the maps can for example be found [here](https://download.osmand.net/list.php). Examples of region files can be found in the `/data` folder. Given the composition of the file names in the osm repo, multiple levels of regions can be used, for example:

* `Belgium`: processes all Belgian maps
* `europe`: processes all maps from european countries (including Belgium, Germany, etc)
* `_`: processes all maps available, as each name contains at least an underscore

Note that the specified regions is case sensitive and the country names are written with a capital
whereas the continent names start with a lower case.

## After the run
After copying the files to your SD card, install the free OSMand app and set the location of the
files in its settings. This location requires to prefix the folder with the location of the SD card.
On an Android device, the prefix is typically in the form `/storage/NNNN-NNNN/`, where each N is a digit. To find the values for N, take a picture with the camera and identify its location in Gallery properties or use a proper file browser.

