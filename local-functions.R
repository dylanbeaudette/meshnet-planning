
#' @param f file, output from `meshtastic --nodes`
parseNodeData <- function(f) {
  
  # read / parse the pretty-printed version of the output
  x <- readLines(f)[-1]
  
  x <- x[grep('════', x, fixed = TRUE, invert = TRUE)]
  
  x <- x[grep('├────', x, fixed = TRUE, invert = TRUE)]
  
  x <- stri_split_fixed(x, pattern = '│', simplify = TRUE)
  
  # extract columns of data
  x <- x[, 2:20]
  
  # column header
  h <- x[1, ]
  h <- trimws(h)
  
  # rows of data
  x <- x[-1, ]
  
  x <- as.data.frame(x)
  names(x) <- h
  
  x <- lapply(x, trimws)
  
  x <- lapply(x, \(i) { ifelse(i == 'N/A', NA_character_, i) })
  
  x <- as.data.frame(x)
  
  
  x$Latitude <- suppressWarnings(
    as.numeric(gsub('°', '', x$Latitude))
  )
  
  x$Longitude <- suppressWarnings(
    as.numeric(gsub('°', '', x$Longitude))  
  )
  
  # encode date/time
  x$LastHeard <- as.POSIXct(x$LastHeard)
  
  # subset columns
  x <- x[, c('User', 'ID', 'AKA', 'Role', 'Latitude', 'Longitude', 'LastHeard')]
  
  return(x)
}


flattenNodeData <- function(db) {
  
  .s <- split(db, db$ID)
  
  # keep the last heard record
  .res <- lapply(.s, \(i) {
    
    # multiple entries
    if(nrow(i) > 1) {
      i <- i[order(i$LastHeard, decreasing = TRUE), ]
      .n <- i[1, ]
    } else {
      # single entry, LastHeard may be NA
      .n <- i[1, ]
    }
    
    return(.n)
  })
  
  .res <- do.call('rbind', .res)
  
  return(.res)
}


