

parseNodeData <- function(f) {
  
  x <- readLines(f)[-1]
  
  x <- x[grep('════', x, fixed = TRUE, invert = TRUE)]
  
  x <- x[grep('├────', x, fixed = TRUE, invert = TRUE)]
  
  x <- stri_split_fixed(x, pattern = '│', simplify = TRUE)
  
  x <- x[, 2:20]
  
  h <- x[1, ]
  h <- trimws(h)
  
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
  
  return(x)
}