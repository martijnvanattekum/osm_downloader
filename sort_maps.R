sort_by_continent <- function(sortdir, continents) {
    files <- list.files(sortdir)
    
    walk(continents, function(continent){
        regiondir <- paste(sortdir, continent, sep="/")
        if (!dir.exists(regiondir)) dir.create(regiondir)
        files_to_move <- files[str_detect(files, continent)]
        walk(files_to_move, function(fl){
            file.rename(paste(sortdir, fl, sep="/"), paste(sortdir, continent, fl, sep="/"))
        })
    })
}