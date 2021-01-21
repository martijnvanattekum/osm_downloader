filter_regions <- function(filenames, regions) {
  if (is.null(regions)) return(filenames)
  files_per_region <- map(regions %>% set_names(), ~{
    matched_files <- filenames %>% .[str_detect(., .x)]
    if (length(matched_files) == 0) warning(paste("No files found for region", .x))
    matched_files
  })
  files_per_region %>% unlist() %>% unname()
}


############ CONTANTS ################
# the convention that osm uses
file_type_suffixes <- c(
  maps = "files/",
  srtm = "files/srtm/",
  tiles = "files/tiles/"
)