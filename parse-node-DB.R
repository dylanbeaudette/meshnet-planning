library(stringi)
library(jsonlite)
library(purrr)
library(data.table)

source('local-functions.R')

# output from `meshtastic --nodes` ----
# NOTE: does not include node number
parseNodeData('node-db-files/OxFC-02.txt')



# output from `meshtastic --info` ----
# !!! 
# NOTE: this will contain channel information and private keys !!
# NOTE: must edit-out node preferences, channels, PSK, etc
#
x <- fromJSON('node-db-json/info-example.json', simplifyDataFrame = TRUE, flatten = TRUE)

# str(x[[1]])
# names(x[1])

prepareNodeData <- function(i) {
  
  .res <- list(
    user = as.data.frame(i$user),
    pos = as.data.frame(i$position)
  )
  
  if(nrow(.res$user) > 0) {
    .res$user$n <- i$num
  }
  
  if(nrow(.res$pos) > 0) {
    .res$pos$n <- i$num
  }
  
  return(.res)
}

flattenNodeData <- function(x) {
  .n <- map(x, .f = prepareNodeData)
  
  .user <- map(.n, pluck, 'user')
  .user <- rbindlist(.user, fill = TRUE)
  .user <- as.data.frame(.user)
  
  .pos <- map(.n, pluck, 'pos')
  .pos <- rbindlist(.pos, fill = TRUE)
  .pos <- as.data.frame(.pos)
  
  .pos$latitudeI <- NULL
  .pos$longitudeI <- NULL
  
  .res <- merge(.user, .pos, by = 'n', all.x = TRUE, sort = FALSE)
 
  return(.res) 
}

z <- flattenNodeData(x)

head(z)
table(z$role)

nrow(z)

