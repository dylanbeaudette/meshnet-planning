library(igraph)
library(stringi)

source('local-functions.R')

# data collected from MeshSense ----
# https://affirmatech.com/meshsense
# set logfile to 100000 lines
# ran 10pm -> 6am
x <- read.csv('mesh-sense-logs/2026-03-09.csv')

# node database from meshtastic CLI
db <- parseNodeData('node-db-files/OxFC.txt')



# review contents ----
# looks like the entire time period is represented
head(x)
tail(x)
nrow(x)

# looks like we can use the message type to filter
table(x$Channel)
table(x$SNR)
table(x$Type)
table(x$Hops)


# are these MQTT messages?
x[x$SNR == 'MQTT', ]

# mixture of successful and unsuccessful ? connections?
e <- grepl(' to ', x$Nodes, fixed = TRUE) & x$Hops != ''
idx <- which(e)
x[idx, ]


# I think that these are successful routes
e <- grepl('traceroute', x$Type, ignore.case = TRUE) & x$Hops != ''
idx <- which(e)
x[idx, ]

# successful message traffic, I think
e <- x$Hops != ''
idx <- which(e)
x[idx, ]



 
# keep successful routes, ignore MQTT ----
e <- grepl('traceroute', x$Type, ignore.case = TRUE) & x$Hops != '' & x$SNR != 'MQTT'
idx <- which(e)
z <- x[idx, ]


# routes -> matrix
r <- stri_split_fixed(z$Data, pattern = ' -> ', simplify = FALSE)

toEdgeList <- function(i) {
  # reduce to graph edges via sliding window
  .el <- sapply(1:(length(i) - 1), \(j) cbind(i[j], i[j+1]))
  t(.el)
}

# convert route matrix to edge list
e <- lapply(r, FUN = toEdgeList)
e <- do.call('rbind', e)

# create and style graph ----
g <- graph_from_edgelist(e, directed = TRUE)

# remove loops
g <- simplify(g)

# lookup names
nm <- V(g)$name
# just IDs to convert
n <- nm[grep('^[!]', nm)]

# replace IDs with names
idx <- na.omit(match(n, db$ID))
lut <- db[idx, c('ID', 'AKA')]

nm[match(lut$ID, nm)] <- lut$AKA
V(g)$name <- nm

# size ~ connectivity
V(g)$size <- sqrt(degree(g)) * 10


par(mar = c(0, 0, 0, 0))

set.seed(1010101)
plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2, vertex.label.cex = 0.66, edge.arrow.size = 0.5, edge.color = 'royalblue', layout = layout_with_dh)
title('Sierra and Surrounding Meshtastic Network', line = -1.5, sub = 'excluding MQTT')


ragg::agg_png(filename = 'figures/sierra-ms-log-graph-01.png', width = 900, height = 900, scaling = 1.5)

par(mar = c(0, 0, 0, 0))

set.seed(1010101)
plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2, vertex.label.cex = 0.66, edge.arrow.size = 0.5, edge.color = 'royalblue', layout = layout_with_dh)
title('Sierra and Surrounding Meshtastic Network', line = -1.5, sub = 'excluding MQTT')

dev.off()



