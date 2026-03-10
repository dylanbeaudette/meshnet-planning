library(elevatr)
library(sf)
library(terra)

# https://casoilresource.lawr.ucdavis.edu/gmap/?loc=38.00982,-120.41187,z13
# Sonora, CA
bb <- '-120.7253 37.7805,-120.7253 38.3228,-119.8622 38.3228,-119.8622 37.7805,-120.7253 37.7805'
wkt <- sprintf("POLYGON((%s))", bb)
a <- vect(wkt, crs = 'epsg:4326')

# ~ 60m (z = 10)
# ~ 30m (z = 11)
# ~ 8m (z = 13)
# ~ 4m (z = 14)
e <- get_elev_raster(st_as_sf(a), z = 10)

# convert to spatRaster
e <- rast(e)

# reasonable local CRS: UTM z10 32610
# consider warping in GRASS with r.proj
# 
e.utm <- terra::project(e, 'epsg:32610', method = 'cubicspline')


# save
terra::writeRaster(e.utm, filename = 'local-data/elev-60m.tif', overwrite = TRUE, gdal = list('COMPRESS=LZW'))



# r.in.gdal in=local-data/elev-60m.tif out=elev60 --overwrite
# g.region -ap rast=elev60
# r.relief --overwrite input=elev60@PERMANENT out=shade60





