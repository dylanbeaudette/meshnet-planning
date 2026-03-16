library(terra)
library(rgrass)
library(purrr)
library(igraph)

## randomized points
# g.region res=16 -ap
# v.random --overwrite output=pts npoints=20
# 
# n <- 75
# execGRASS('v.random', flags = 'overwrite', npoints = n, output = 'pts')


## hand-digitized points
# v <- read_VECT('pts')

## real coordinates
# manually edit to remove inactive nodes
v <- read.csv('SIERRA Meshtastic Node Locations - Node Locations.csv')

# subset, re-name
v <- v[, c('Short.Name', 'Lat', 'Lon', 'AGL')]
v$node <- v$Short.Name


v <- vect(v, geom = c('Lon', 'Lat'), crs = 'epsg:4326')
v <- project(v, 'epsg:32610')
 
write_VECT(v, vname = 'pts', flags = 'overwrite')

# extract coordinates for r.viewshed
xy <- crds(v)
n <- nrow(v)

execGRASS('g.region', flags = c('a', 'p'), raster = 'elev60')
execGRASS('g.remove', flags = 'f', type = 'raster', pattern = 'vs_*')

walk(1:n, .progress = TRUE, .f = function(i) {
  
  .map <- sprintf("vs_%0.3d", i)
  .coords <- round(xy[i, ])
  
  execGRASS(
    cmd = 'r.viewshed', 
    flags = c('c', 'r', 'b', 'overwrite'), 
    input = 'elev60', 
    output = .map, 
    coordinates = .coords, 
    observer_elevation = 3, 
    target_elevation = v$AGL[i], 
    ignore.stderr = TRUE
  )
})

r <- execGRASS('g.list', type='raster', pattern='vs_*', Sys_ignore.stdout = TRUE)
r.names <- attr(r, 'resOut')
x <- map(r.names, .progress = TRUE, .f = read_RAST, ignore.stderr = TRUE)

x <- rast(x)
names(x) <- r.names

# writeRaster(x, filename = 'pts-stack.tif')

plot(x[[1:12]], axes = FALSE, col = c(NA, 2))

plot(x[[2]], axes = FALSE, col = c(NA, 2))
points(v[2, ])
text(v, pos = 3)

# remove points + maps where LOS is all 0

e <- extract(x, v)
# row.names(e) <- r.names

m <- as.matrix(e[, -1])
dimnames(m)[[1]] <- v$node
dimnames(m)[[2]] <- v$node

saveRDS(m, file = 'local-data/pts-adjmat.rds')

# m <- readRDS('local-data/pts-adjmat.rds')



g <- graph_from_adjacency_matrix(m, mode = 'lower', diag = FALSE, weighted = TRUE)

g <- simplify(g)

V(g)$size <- sqrt(degree(g)) * 8

par(mar = c(0, 0, 0, 0))

set.seed(1010101)
plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2, layout = layout_as_star)

plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2, layout = layout_as_tree)


set.seed(1010101)
plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2, vertex.label.cex = 0.66, edge.arrow.size = 0.25, edge.color = 'royalblue')


ragg::agg_png(filename = 'figures/sierra-viewshed-estimate.png', width = 900, height = 900, scaling = 1.5)

par(mar = c(0, 0, 0, 0))

set.seed(1010101)
plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2, vertex.label.cex = 0.66, edge.arrow.size = 0.25, edge.color = 'royalblue')

title('Sierra Meshtastic Network', line = -1.5, sub = 'links defined by viewshed')

dev.off()



s <- sum(x)
plot(s, axes = FALSE, col = c('grey', hcl.colors(25, palette = 'mako')))
points(v, col = 2)

write_RAST(s, vname = 's', flags = 'overwrite')
execGRASS('r.null', map = 's', setnull = '0')


el <- as_edgelist(g)

plot(v, axes = FALSE, type = 'n')

for(i in 1:nrow(el)) {
  .el <- el[i, ]
  .nodeidx <- match(.el, v$node)
  segments(
    x0 = xy[.nodeidx[1], 1], 
    y0 = xy[.nodeidx[1], 2],
    x1 = xy[.nodeidx[2], 1], 
    y1 = xy[.nodeidx[2], 2]
    )
}

points(v, cex = 2.5, col = 2)
text(v, cex = 0.66)

# ln <- lapply(1:nrow(el), function(i) {
#   .el <- el[i, ]
#   cbind(
#     x0 = xy[.el[1], 1], 
#     y0 = xy[.el[1], 2],
#     x1 = xy[.el[2], 1], 
#     y1 = xy[.el[2], 2]
#   )
# })
# 
# ln <- do.call('rbind', ln)
# 
# ln <- vect(ln, type = 'line', crs = crs(v))
# ln$id <- 1:nrow(ln)
# plot(ln)
# 


