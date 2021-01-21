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
  make_option(c("-l", "--local-dir"), type="character", default="./", 
              help="The local directory where the downloaded files are"),
  make_option(c("-l", "--remote-dir"), type="character", 
              help="The remote directory to which the downloaded files will be copied.")
)

file_types <- c("maps", "srtm", "tiles") %>% 
  .[c(!opt[["no-maps"]], !opt[["no-contours"]], !opt[["no-hillshade"]])] %>% 
  set_names()
local_root_folder <- opt["local-dir"]
remote_root_folder <- opt["remote-dir"]
if (!opt[["all-regions"]]) regions_of_interest <- readLines("regions.txt") else regions_of_interest <- NULL

############ FUNCTIONS ################
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



# copy maps of interest
walk2(local_folders, remote_folders, ~copy_data(.x, .y, regions_of_interest))


copy_data(local_folders["srtm"], remote_folders["srtm"], regions_of_interest)
