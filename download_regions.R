#bulk downloads osm maps, contour and hillshade files

############ INIT ################
suppressPackageStartupMessages({
  library(rvest)
  library(dplyr)
  library(purrr)
  library(fs)
  library(stringr)
  library(optparse)
})

source("base_functions.R")

############ CLA PARSING ################
option_list <- list( 
  make_option(c("-m", "--no-maps"), action="store_true", default=FALSE,
              help="Do not download the map files"),
  make_option(c("-c", "--no-contours"), action="store_true", default=FALSE,
              help="Do not download the altitude lines files"),
  make_option(c("-t", "--no-hillshade"), action="store_true", default=FALSE,
              help="Do not download the hillshade files"),
  make_option(c("-r", "--regions-file"), type="character", default="./regions.txt", 
              help="The path to the regions file. Defaults to regions.txt in the current directory"),
  make_option(c("-l", "--local-dir"), type="character", default="~/osm_downloads", 
              help="The local directory to which to download the files. Defaults to ~/osm_downloads")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

file_types_to_process <- c("maps", "srtm", "tiles") %>% 
  .[c(!opt[["no-maps"]], !opt[["no-contours"]], !opt[["no-hillshade"]])] %>% 
  set_names()
regions_of_interest <- readLines(opt[["regions-file"]])

cat(paste0("** Preparing download of ", paste(file_types_to_process, collapse=", "),".\n"))

############ CONTANTS ################
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
safe_dl <- safely(function(link_prefix, basename, downloadfolder, extract = TRUE){
  
  #create downloaddir and define destination names
  fs::dir_create(downloadfolder)
  dest_file <- path(downloadfolder, basename) #dest file
  dest_file_unzipped <- path_ext_remove(dest_file) #dest_file without zip extension
  
  #download the file
  if (fs::file_exists(dest_file) || fs::file_exists(dest_file_unzipped)) {
  cat(paste0(dest_file, " already exists, SKIPPING!\n"))} else {
  cat(paste0("Downloading to file ", dest_file))
  download.file(url = paste0(link_prefix, basename),
                destfile = dest_file,
                method = "auto", 
                cacheOK = TRUE,
                quiet = TRUE)
    if (fs::file_exists(dest_file)) {
      cat(" -- FINISHED!\n")} else {cat(" -- FAILED!\n")}
    }
  
  #unzip the file
  if (path_ext(basename) == "zip" && (fs::file_exists(dest_file)) && extract){
    cat(paste0(" -> Starting unzip of ", basename))
    unzip(zipfile = dest_file, exdir = downloadfolder)
    unlink(x = dest_file)
    if (fs::file_exists(dest_file_unzipped)) {
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
local_folders <- opt["local-dir"] %>% 
  path(file_type_suffixes) %>% 
  set_names(names(file_type_suffixes))
  
basenames <- map(file_types_to_process, ~{
  index_of_files[[.x]] %>% 
    filter_regions(regions_of_interest)
  })
  
for (file_type in file_types_to_process){
  cat(paste("** Starting downloads of", file_type, "\n"))
  link_prefix <- remote_prefixes[file_type]
  downloadfolder <- local_folders[file_type]
  for (basename in basenames[[file_type]]){
    safe_dl(link_prefix, basename, downloadfolder)
  }
}


