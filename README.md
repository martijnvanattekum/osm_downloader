# OSM map tools
Tools to download, process and copy osm maps, altitute lines and hillshades. 

# Requirements
An installation of R (with Rscript executable) >3.6 and the following installed packages:

* rvest
* dplyr
* purrr
* stringr
* optparse

# Usage
The following scripts can be used

* Downloading (download_regions.R): downloads osm files to a local directory
* Copying (copy_regions.R): copies files from local to remote directory. Typically used to copy the files to an SD card

Both scripts by default read in the file `regions.txt`, which specifies which regions are downloaded
or copied. Also by default, the scripts download map files, altitude lines and hillshades for
those regions.

## Command line arguments
Run `Rscript download_regions.R -h` to get an overview of commandline options

## regions.txt
The regions.txt file resides in the same folder as the R script and contains one region that should
be processed on each line. When a region occurs in the filename, that file is processed. This means
that both `Belgium` and `europe` are valid regions. Note that the specified regions is case sensitive.

## After the run
After copying the files to your SD card, install the free OSMand app and set the location of the
files in its settings. This location requires to prefix the folder with the location of the SD card.
The prefix is typically in the form `/storage/NNNN-NNNN/`, where each N is a digit. To find the values
for N, take a picture with the camera and identify its location in Gallery properties or use a 
proper file browser.



