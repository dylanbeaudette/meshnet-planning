library(terra)
library(rgrass)
library(purrr)
library(igraph)

# g.region res=16 -ap
# v.random --overwrite output=pts npoints=20

# n <- 75
execGRASS('g.region', flags = c('a', 'p'), res = '32')
# execGRASS('v.random', flags = 'overwrite', npoints = n, output = 'pts')

# digitized these
v <- read_VECT('pts')
xy <- crds(v)

n <- nrow(v)

execGRASS('g.remove', flags = 'f', type = 'raster', pattern = 'vs_*')

walk(1:n, .progress = TRUE, .f = function(i) {
  
  .map <- sprintf("vs_%0.3d", i)
  .coords <- round(xy[i, ])
  
  execGRASS(
    cmd = 'r.viewshed', 
    flags = c('c', 'r', 'b', 'overwrite'), 
    input = 'elev', 
    output = .map, 
    coordinates = .coords, 
    observer_elevation = 3, 
    target_elevation = 2, 
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
row.names(e) <- r.names

m <- as.matrix(e[, -1])

saveRDS(m, file = 'pts-adjmat.rds')


g <- graph_from_adjacency_matrix(m, mode = 'lower', diag = FALSE, add.colnames = TRUE, weighted = TRUE)

V(g)$size <- sqrt(degree(g)) * 5

par(mar = c(0, 0, 0, 0))

set.seed(1010101)
plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2, layout = layout_as_star)

set.seed(1010101)
plot(g, vertex.label.family = 'sans', vertex.color = 'white', vertex.label.color = 'black', vertex.label.font = 2)


s <- sum(x)
plot(s, axes = FALSE, col = c('grey', hcl.colors(25, palette = 'mako')))
points(v, col = 2)



el <- as_edgelist(g)

plot(v, axes = FALSE, type = 'n')

for(i in 1:nrow(el)) {
  .el <- el[i, ]
  segments(
    x0 = xy[.el[1], 1], 
    y0 = xy[.el[1], 2],
    x1 = xy[.el[2], 1], 
    y1 = xy[.el[2], 2]
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


