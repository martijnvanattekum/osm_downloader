#bulk downloads osm maps, contour and hillshade files

############ INIT ################
suppressPackageStartupMessages({
  library(rvest)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(optparse)
})

############ CLA PARSING ################
option_list <- list( 
  make_option(c("-a", "--all-regions"), action="store_true", default=FALSE,
              help="Ignore regions.txt and download all regions"),
  make_option(c("-m", "--no-maps"), action="store_true", default=FALSE,
              help="Do not download the map files"),
  make_option(c("-c", "--no-contours"), action="store_true", default=FALSE,
              help="Do not download the altitude lines files"),
  make_option(c("-t", "--no-hillshade"), action="store_true", default=FALSE,
              help="Do not download the hillshade files"),
  make_option(c("-l", "--local-dir"), type="character", default="./", 
              help="The local directory to which to download the files. Defaults to current directory")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

file_types <- c("maps", "srtm", "tiles") %>% 
  .[c(!opt[["no-maps"]], !opt[["no-contours"]], !opt[["no-hillshade"]])] %>% 
  set_names()
local_root_folder <- opt["local-dir"]
if (!opt[["all-regions"]]) regions_of_interest <- readLines("regions.txt") else regions_of_interest <- NULL

############ CONTANTS ################
# the convention that osm uses
file_type_suffixes <- c(
  maps = "files/",
  srtm = "files/srtm/",
  tiles = "files/tiles/"
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
safe_dl <- safely(function(link_prefix, basename, downloadfolder, extract = TRUE){
  
  #create downloaddir and define destination names
  if (!dir.exists(downloadfolder)) dir.create(downloadfolder, recursive = TRUE)
  dest_file <- paste0(downloadfolder, basename) #dest file
  dest_file_unzipped <- str_sub(dest_file, 1, -5) #dest_file without zip extension
  
  #download the file
  if (file.exists(dest_file) || file.exists(dest_file_unzipped)) {
  cat(paste0(dest_file, " already exists, SKIPPING!\n"))} else {
  cat(paste0("Downloading to file ", dest_file))
  download.file(url = paste0(link_prefix, basename),
                destfile = dest_file,
                method = "auto", 
                cacheOK = TRUE,
                quiet = TRUE)
    if (file.exists(dest_file)) {
      cat(" -- FINISHED!\n")} else {cat(" -- FAILED!\n")}
    }
  
  #unzip the file
  if (str_detect(basename, "\\.zip$") && (file.exists(dest_file)) && extract){
    cat(paste0(" -> Starting unzip of ", basename))
    unzip(zipfile = dest_file, exdir = str_sub(downloadfolder, 1, -2)) # remove trailing slash to avoid error
    unlink(x = dest_file)
    if (file.exists(dest_file_unzipped)) {
      cat(" -- FINISHED!\n")} else {cat(" -- FAILED!\n")}
  }
}
)

filter_regions <- function(filenames, regions) {
  if (is.null(regions)) return(filenames)
  files_per_region <- map(regions %>% set_names(), ~{
    matched_files <- filenames %>% .[str_detect(., .x)]
    if (length(matched_files) == 0) warning(paste("No files found for region", .x))
    matched_files
  })
  files_per_region %>% unlist() %>% unname()
}

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
local_folders <- map_chr(file_type_suffixes, ~paste0(local_root_folder, .x))
basenames <- map(file_types, ~{
  index_of_files[[.x]] %>% 
    filter_regions(regions_of_interest)
  })
  
for (file_type in file_types){
  cat(paste("** Starting downloads of", file_type, "\n"))
  link_prefix <- remote_prefixes[file_type]
  downloadfolder <- local_folders[file_type]
  for (basename in basenames[[file_type]]){
    safe_dl(link_prefix, basename, downloadfolder)
  }
}


