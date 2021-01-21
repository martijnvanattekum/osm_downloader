#bulk downloads all osm maps, contour and hillshade files
#Home folder on SD card (~): /Android/data/net.osmand
#Extension  Type          Location  Web_location
#.obf:      standard maps ~         http://download.osmand.net/rawindexes/
#.srtm.obf  contour lines ~/srtm    http://builder.osmand.net/srtm-countries/
#.sqlitedb  hillshade     ~/tiles   http://fides.fe.uni-lj.si/~arpadb/osmand/

#To find location of osmand to link to: take a pic with camera, and identify
#its location in Gallery properties and derive maps folder from there
#eg /storage/6432-3234/Android/data/net.osmand or 6630-6132

############ INIT ################
library(rvest)
library(tidyverse)

# copy maps/contours/hillshades from source dir recursively to dest
# only taking files from region(s) of interest (either countries or continents).
copy_data <- function(src, dest, regions) {
  if (!dir.exists(dest)) dir.create(dest, recursive = TRUE)
  if (!dir.exists(src)) warning(paste("Source dir", src, "does not exist!"))
  
  files_in_scr_dir <- list.files(src, recursive = TRUE, full.names = TRUE)
  files_to_copy_list <- map(regions %>% set_names(), ~{
    detected_files <- files_in_scr_dir %>% .[str_detect(., .x)]
    if (length(detected_files) == 0) warning(paste("No files found for region", .x))
    detected_files
  })
  
  files_to_copy <- files_to_copy_list %>% unlist %>% unname()
  
  n_files <- length(files_to_copy)
  iwalk(files_to_copy, ~{
    cat(paste0("copying file ", .y, "/", n_files, " (", basename(.x), ")\n" ))
    file.copy(.x, dest, overwrite = FALSE)})
  
  files_in_dest_dir <- list.files(dest)
  scr_not_in_dest <- setdiff(basename(files_to_copy), files_in_dest_dir)
  if (length(scr_not_in_dest) != 0) warning(paste("The following files were not copied:", scr_not_in_dest))
}

############ PROGRAM ################
#get the names of the mapfiles from the index pages
map_files_functions <- list(

  maps = read_html(maps_index) %>% 
    html_node("table") %>% #extract the table
    html_table() %>% #convert to table format
    as_tibble %>%  #create tibble
    dplyr::filter(str_detect(Description, "Map")) %>% #filter actual map files
    pull(File)  #pull file names
  
  srtm = read_html(srtm_index) %>% 
    html_nodes("a") %>% 
    html_attr('href') %>% 
    .[str_detect(., "\\.srtm\\.obf") & !is.na(.)]
  
  tiles = read_html(hillshade_index) %>%
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

remote_prefixes <- c(maps = "http://download.osmand.net/download.php?standard=yes&file=",
                     srtm = "http://builder.osmand.net/srtm-countries/",
                     tiles = "http://download.osmand.net/download.php?hillshade=yes&file=")

basenames <- 
download_results <- 

res_maps <- map(mapfiles, ~safe_dl(link_prefix = "http://download.osmand.net/download.php?standard=yes&file=",
                                   mapfile = .x, 
                                   downloadfolder = local_root_folder))
res_srtm <- map(srtmfiles, ~safe_dl(link_prefix = "http://builder.osmand.net/srtm-countries/", 
                                    mapfile = .x, 
                                    downloadfolder = paste))
res_hill <- map(hillfiles, ~safe_dl(link_prefix = "http://download.osmand.net/download.php?hillshade=yes&file=",  #NOTE: add back the hillshade=yes which was removed from the end of the links previously
                                    mapfile = .x, 
                                    downloadfolder = "D:\\OSMdownloads\\hillshade\\"))

which_failed(res_hill)

remote_root_folder <- "/Volumes/SD_200GB/Android/data/net.osmand/"
remote_folders <- map_chr(file_types, ~paste0(remote_root_folder, .x))

#walk(folders_to_sort, ~sort_by_region(sortdir = .x, regions = regions))

dest_home <- "/Volumes/SD_200GB/Android/data/net.osmand/"
regions_of_interest <- c("Andorra", "Austria", "Azores", "Belgium",  
                           "Cyprus", "Faroe-islands", "France", "Germany", "Greece", "Isle-of-man", 
                           "Italy", "Liechtenstein", "Luxembourg", "Malta", "Monaco", "Netherlands", 
                           "Portugal", "San-marino", "Slovenia", "Spain", "Switzerland", "World")
#regions_of_interest <- "europe"

# copy maps of interest
walk2(local_folders, remote_folders, ~copy_data(.x, .y, regions_of_interest))


copy_data(local_folders["srtm"], remote_folders["srtm"], regions_of_interest)
