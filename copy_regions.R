# copies regional files to another location (typically phone storage)

############ INIT ################
suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
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
              help="The local directory to which to download the files. Defaults to current directory"),
  make_option(c("-l", "--local-dir"), type="character", default="./", 
              help="The local directory where the downloaded files are"),
  make_option(c("-d", "--destination-dir"), type="character", 
              help="The remote directory to which the downloaded files will be copied.")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

file_types <- c("maps", "srtm", "tiles") %>% 
  .[c(!opt[["no-maps"]], !opt[["no-contours"]], !opt[["no-hillshade"]])] %>% 
  set_names()
local_root_folder <- opt["local-dir"]
remote_root_folder <- opt["destination-dir"]
regions_of_interest <- readLines(opt[["regions-file"]])

############ FUNCTIONS ################
# copy maps/contours/hillshades from source dir recursively to dest
# only taking files from region(s) of interest (either countries or continents).
copy_file <- function(src, dest, filename) {
  if (!dir.exists(dest)) dir.create(dest, recursive = TRUE)
  stopifnot(dir.exists(src)) 
  
  src_file <- paste0(src, filename)
  dest_file <- paste0(dest, filename)
  
  file.copy(src_file, dest_file, overwrite = FALSE)
}

############ PROGRAM ################
local_folders <- map_chr(file_type_suffixes, ~paste0(local_root_folder, .x))
remote_folders <- map_chr(file_type_suffixes, ~paste0(remote_root_folder, .x))

filenames_per_type <- map(file_types, ~{
  list.files(local_folders[[.x]]) %>% 
    filter_regions(regions_of_interest)
})

for (file_type in file_types){
  cat(paste("** Starting copying of", file_type, "\n"))
  local_folder <- local_folders[[file_type]]
  remote_folder <- remote_folders[[file_type]]
  filenames <- filenames_per_type[[file_type]]
  n_files <- length(filenames)
  iwalk(filenames, ~{
    cat(paste0("copying file ", .y, "/", n_files, " (", basename(.x), ")\n" ))
    copy_file(local_folder, remote_folder, .x)
  })
}

