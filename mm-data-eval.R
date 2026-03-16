## TODO:

# * split between stationary / mobile nodes
# * think about the use / interpretation of edge weights
# * reset edge weights for nodes used to collect traceroute information



library(igraph)
library(stringi)
library(digest)

source('local-functions.R')

# data collected from MeshSense ----
# https://affirmatech.com/meshsense
# set logfile to 100000 lines
# let run for as long as possible

f <- list.files('mesh-sense-logs/', full.names = TRUE)
x <- lapply(f, read.csv)
x <- do.call('rbind', x)

# node database from meshtastic CLI ----
f <- list.files('node-db-files/', full.names = TRUE)
db <- lapply(f, parseNodeData)
db <- do.call('rbind', db)

# there should be no duplicates
db <- flattenNodeData(db)
nrow(db)


# known local nodes ----
# nl <- read.csv('local-nodes.csv')


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

# there may be multiple versions of the same traceroute 
sort(table(z$Data))

# there should be no NA in z$Data
stopifnot(! any(is.na(z$Data)))


# replace user ID with short name using node DB

# all short names / ID
nm <- stri_split_fixed(z$Data, pattern = ' -> ', simplify = TRUE)
nm <- unique(as.vector(nm))

# filter non-names
nm <- nm[which(nm != '')]
nm <- nm[which(nm != 'all')]

# extract IDs to convert
n <- nm[grep('^[!]', nm)]

# replace IDs with names
idx <- na.omit(match(n, db$ID))
lut <- db[idx, c('ID', 'AKA')]

# remove records from LUT missing short nams
lut <- na.omit(lut)

# replace known IDs with short name
for(i in 1:nrow(lut)) {
  z$Data <- gsub(pattern = lut$ID[i], replacement = lut$AKA[i], x = z$Data, fixed = TRUE)
}

# grep('!a9e00e2f', z$Data, fixed = TRUE)

# lattice::dotplot(sort(table(z$Data)))

sort(table(z$Data))

# there should be no NA in z$Data
any(is.na(z$Data))


# there may be duplicate routes
# routes -> matrix
r <- stri_split_fixed(
  z$Data, 
  pattern = ' -> ', 
  simplify = FALSE
)

toEdgeList <- function(i) {
  # reduce to graph edges via sliding window
  .el <- sapply(1:(length(i) - 1), \(j) cbind(i[j], i[j+1]), simplify = TRUE)
  t(.el)
}

# convert route matrix to edge list
e <- lapply(r, FUN = toEdgeList)
e <- do.call('rbind', e)


# ignore "all" in traceroutes
idx <- which(e[, 1] != 'all' & e[, 2] != 'all')
e <- e[idx, ]

# duplicate routes should be encoded as additional edge weight
# create edge hash for ID
e <- as.data.frame(e)
e$hash <- NA
for(i in 1:nrow(e)) {
  e$hash[i] <- digest(unlist(e[i, 1:2]))
}

# aggregate edge counts into edge weights
tab <- table(e$hash)
a <- lapply(names(tab), \(i) {
  # keep the first edge definition for each hash
  .idx <- match(i, e$hash)[1]
  e[.idx, ]
})

a <- do.call('rbind', a)
a$wt <- tab


# create and style graph ----
# treat trace routes as bi-directional links
g <- graph_from_edgelist(
  as.matrix(a[, 1:2]), 
  directed = FALSE
)

# TODO: not clear what we would actually do with this weight
#       0xFC -> MT is the most common link because this is where the 
#       data are coming from
E(g)$weight <- log(a$wt) + 1


# remove loops
g <- simplify(g)

# size ~ connectivity
V(g)$size <- pmin(pmax(sqrt(degree(g)) * 5, 7), 15)

# highlight routers
.routers <- db$AKA[grep('router', db$Role, ignore.case = TRUE)]
idx <- which(V(g)$name %in% .routers)
V(g)$shape <- 'circle'
V(g)$shape[idx] <- 'square'

V(g)$frame.width <- 1
V(g)$frame.width[idx] <- 1.5


# adjust label size when short name is missing
V(g)$label.cex <- 0.66
idx <- which(nchar(V(g)$name) > 4)
V(g)$label.cex[idx] <- 0.5


par(mar = c(0, 0, 0, 0))

# set.seed(1010101)
plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', edge.color = 'royalblue', layout = layout_with_lgl)
title('Sierra and Surrounding Meshtastic Network', line = -1.5, sub = 'excluding MQTT')


plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2, edge.color = 'royalblue', layout = layout_as_tree)

plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2, edge.color = 'royalblue', layout = layout_as_star)



g.sub <- subgraph(g, which(degree(g) > 2))
plot(g.sub, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', edge.color = 'royalblue', layout = layout_with_lgl)

plot(g.sub, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', edge.color = 'royalblue', layout = layout_as_star)



ragg::agg_png(filename = 'figures/sierra-ms-log-graph-01.png', width = 2000, height = 2000, scaling = 2.5)

par(mar = c(0, 0, 0, 0))

# set.seed(1010101)
plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', edge.arrow.size = 0.25, edge.color = 'royalblue', layout = layout_with_dh)
title('Sierra and Surrounding Meshtastic Network', line = -1.5, sub = 'excluding MQTT')

dev.off()





ragg::agg_png(filename = 'figures/sierra-ms-log-graph-02.png', width = 1000, height = 1000, scaling = 1.66)

par(mar = c(0, 0, 1, 0))

# set.seed(1010101)
plot(g.sub, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', edge.arrow.size = 0.25, edge.color = 'royalblue', layout = layout_with_dh)
title('Sierra and Surrounding Meshtastic Network\ndegree > 2', line = -1.5, sub = 'excluding MQTT')

dev.off()




# TODO: include community detection
# plot(cluster_walktrap(g), g)
# plot(cluster_fast_greedy(g), g)


m <- membership(cluster_fast_greedy(g))

cr <- colorRampPalette(hcl.colors(n = 20, palette = 'spectral'), space = 'Lab')
cols <- cr(length(unique(m)))
cols <- scales::alpha(cols, alpha = 0.5)




ragg::agg_png(filename = 'figures/sierra-ms-log-graph-03.png', width = 2000, height = 2000, scaling = 2.5)

par(mar = c(0, 0, 0, 0))

plot(g, vertex.label.family = 'sans', vertex.color = cols[m], vertex.label.color = 'black', edge.arrow.size = 0.25, edge.color = 'royalblue', layout = layout_with_dh)
title('Sierra and Surrounding Meshtastic Network', line = -1.5, sub = 'excluding MQTT')

dev.off()




# TODO: do something fun with traceroute data
tr <- unique(z$Data)

tr <- tr[order(sapply(tr, nchar))]

cat(tr, sep = '\n')




