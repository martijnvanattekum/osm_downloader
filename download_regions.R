#bulk downloads osm maps, contour and hillshade files

############ INIT ################
library(rvest)
library(tidyverse)

setwd("/Volumes/D/Google Drive/CODE/repos/osm_downloader")
regions_of_interest <- readLines("regions.txt")

############ CONTANTS ################
# the convention that osm uses
file_type_suffixes <- c(
  maps = "files",
  srtm = "files/srtm",
  tiles = "files/tiles"
)

# websites where the index with all files can be found
index_locations <- c(
  maps = "http://download.osmand.net/rawindexes/",
  srtm = "http://builder.osmand.net/srtm-countries/",
  tiles = "http://fides.fe.uni-lj.si/~arpadb/osmand/"
)

# the prefix after which the basename is added to get a download link
remote_prefixes <- c(
  maps = "http://download.osmand.net/download.php?standard=yes&file=",
  srtm = "http://builder.osmand.net/srtm-countries/",
  tiles = "http://download.osmand.net/download.php?hillshade=yes&file="
)

############ FUNCTIONS ################
#downloads file. If zip: by default also extracts the file, then deletes the zip file
safe_dl <- safely(function(link_prefix, mapfile, downloadfolder, extract = TRUE){
  
  #create downloaddir and define destination names
  if (!dir.exists(downloadfolder)) dir.create(downloadfolder)
  dest_file <- paste0(downloadfolder, mapfile) #dest file
  dest_file_unzipped <- str_sub(dest_file, 1, -5) #dest_file without zip extension
  
  #download the file
  if (file.exists(dest_file) || file.exists(dest_file_unzipped)) {
  cat(paste0(dest_file, " already exists, SKIPPING!\n"))} else {
  cat(paste0("Downloading to file ", dest_file))
  download.file(url = paste0(link_prefix, mapfile),
                destfile = dest_file,
                method = "auto", 
                cacheOK = TRUE,
                quiet = TRUE)
    if (file.exists(dest_file)) {
      cat(" -- FINISHED!\n")} else {cat(" -- FAILED!\n")}
    }
  
  #unzip the file
  if (str_detect(mapfile, "\\.zip$") && (file.exists(dest_file)) && extract){
    cat(paste0(" -> Starting unzip of ", mapfile))
    unzip(zipfile = dest_file, exdir = str_sub(downloadfolder, 1, -2)) # remove trailing slash to avoid error
    unlink(x = dest_file)
    if (file.exists(dest_file_unzipped)) {
      cat(" -- FINISHED!\n")} else {cat(" -- FAILED!\n")}
  }
}
)

############ PROGRAM ################
#get the names of the mapfiles from the index pages
index_of_files <- list(

  maps = read_html(index_locations["maps"]) %>% 
    html_node("table") %>% #extract the table
    html_table() %>% #convert to table format
    as_tibble %>%  #create tibble
    dplyr::filter(str_detect(Description, "Map")) %>% #filter actual map files
    pull(File),  #pull file names
  
  srtm = read_html(index_locations["srtm"]) %>% 
    html_nodes("a") %>% 
    html_attr('href') %>% 
    .[str_detect(., "\\.srtm\\.obf") & !is.na(.)],
  
  tiles = read_html(index_locations["tiles"]) %>%
    html_nodes("a") %>% 
    html_attr('href') %>% 
    .[str_detect(., "Hillshade.+\\.sqlitedb") & !is.na(.)] %>% 
    str_match("^.+file=(.+.sqlitedb)\\&hillshade=yes") %>% #extract the file names from the full links, hillshade=yes will be added back later as prefix
    .[,2]
  )

# download everything to local folder
file_types <- c("maps", "srtm", "tiles") %>% set_names()  #change to decide what is copied
local_root_folder <- "/Volumes/D/OSMdownloads/"
local_folders <- map_chr(file_types, ~paste0(local_root_folder, .x))

basenames <- map(file_types, ~index_of_files[.x])

for (file_type in file_types){
  link_prefix <-  remote_prefixes[file_type]
  downloadfolder <- local_folders[file_type]
  for (basename in basenames[file_type]){
    safe_dl(link_prefix, basename, downloadfolder)
  }
}


