# copies regional files to another location (typically phone storage)

############ INIT ################
suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(fs)
  library(stringr)
  library(optparse)
})

source("base_functions.R")

############ CLA PARSING ################
option_list <- list( 
  make_option(c("-a", "--all-regions"), action="store_true", default=FALSE,
              help="Ignore regions.txt and download all regions"),
  make_option(c("-m", "--no-maps"), action="store_true", default=FALSE,
              help="Do not copy the map files"),
  make_option(c("-c", "--no-contours"), action="store_true", default=FALSE,
              help="Do not copy the altitude lines files"),
  make_option(c("-t", "--no-hillshade"), action="store_true", default=FALSE,
              help="Do not copy the hillshade files"),
  make_option(c("-r", "--regions-file"), type="character", default="./regions.txt", 
              help="The path to the regions file. Defaults to regions.txt in the current directory"),
  make_option(c("-l", "--local-dir"), type="character", default="~/osm_downloads", 
              help="The local directory to which to download the files. Defaults to ~/osm_downloads"),
  make_option(c("-d", "--destination-dir"), type="character", 
              help="The remote directory to which the downloaded files will be copied.")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

file_types_to_process <- c("maps", "srtm", "tiles") %>% 
  .[c(!opt[["no-maps"]], !opt[["no-contours"]], !opt[["no-hillshade"]])] %>% 
  set_names()
regions_of_interest <- readLines(opt[["regions-file"]])

cat(paste0("** Preparing copying of " , paste(file_types_to_process, collapse=", "),".\n"))

############ FUNCTIONS ################
# copy maps/contours/hillshades from source dir recursively to dest
# only taking files from region(s) of interest (either countries or continents).
copy_file <- function(src, dest, filename) {
  fs::dir_create(dest)
  stopifnot(fs::dir_exists(src)) 
  
  src_file <- fs::path(src, filename)
  dest_file <- fs::path(dest, filename)
  
  if (!fs::file_exists(dest_file)) fs::file_copy(src_file, dest_file, overwrite = FALSE)
}

############ PROGRAM ################
local_folders <- opt["local-dir"] %>% 
  fs::path(file_type_suffixes) %>% 
  set_names(names(file_type_suffixes))

destination_folders <- opt["destination-dir"] %>% 
  fs::path(file_type_suffixes) %>% 
  set_names(names(file_type_suffixes))

filenames_per_type <- map(file_types_to_process, ~{
  local_folders[[.x]] %>% 
    fs::dir_ls(type = "file") %>% 
    fs::path_file() %>% 
    filter_regions(regions_of_interest)
})

for (file_type in file_types_to_process){
  cat(paste("** Starting copying of", file_type, "\n"))
  local_folder <- local_folders[[file_type]]
  destination_folder <- destination_folders[[file_type]]
  filenames <- filenames_per_type[[file_type]]
  n_files <- length(filenames)
  iwalk(filenames, ~{
    cat(paste0("copying file ", .y, "/", n_files, " (", basename(.x), ")\n" ))
    copy_file(local_folder, destination_folder, .x)
  })
}

