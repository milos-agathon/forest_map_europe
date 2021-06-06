
# How to overlay spatial polygons on satellite imagery using R
# Milos Popovic
# 2021-06-06"
# install libraries
if(!require("dplyr")) install.packages("dplyr")
if(!require("sf")) install.packages("sf")
if(!require("raster")) install.packages("raster")
if(!require("gdalUtils")) install.packages("gdalUtils")
if(!require("exactextractr")) install.packages("exactextractr")
if(!require("ggplot2")) install.packages("ggplot2")
if(!require("classInt")) install.packages("classInt")

# load libraries
library(dplyr, quietly=T) # data processing
library(sf, quietly=T) # import polygons 
library(raster, quietly=T) #load rasters
library(gdalUtils, quietly=T) # merge rasters
library(exactextractr, quietly=T) # zonal statistics
library(ggplot2, quietly=T) # map
library(classInt, quietly=T) # legend

set.seed(20210604)

# define the 2019 urls
urls <- c(
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/E000N80/E000N80_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/W040N80/W040N80_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/W020N80/W020N80_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/E020N80/E020N80_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/E040N80/E040N80_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/E040N60/E040N60_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/W020N60/W020N60_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/E000N60/E000N60_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/E020N60/E020N60_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/W020N40/W020N40_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/E000N40/E000N40_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/E020N40/E020N40_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif",
"https://s3-eu-west-1.amazonaws.com/vito.landcover.global/v3.0.1/2019/E040N40/E040N40_PROBAV_LC100_global_v3.0.1_2019-nrt_Tree-CoverFraction-layer_EPSG-4326.tif"
)

#DOWNLOAD FILES
for (url in urls) {
    download.file(url, destfile = basename(url), mode="wb")
}

# enlist raster files, merge them into a single file and re-project
rastfiles <- list.files(path = getwd(), 
	pattern = ".tif$",
	all.files=T, 
	full.names=F)
r <- mosaic_rasters(gdalfile=rastfiles,
              dst_dataset="2019_forest_cover.tif",
              of="GTiff")
raster <- '2019_forest_cover.tif'
ras <- stack(raster)
crs(ras) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"

#DOWNLOAD SHAPEFILES
#Communities 2016 shapefile
url <- "https://gisco-services.ec.europa.eu/distribution/v2/communes/download/ref-communes-2016-01m.shp.zip"
download.file(url, basename(url), mode="wb")
unzip("ref-communes-2016-01m.shp.zip")
unzip("COMM_RG_01M_2016_4326.shp.zip")

#Eurostat 2013 country shapefile
url <- "https://gisco-services.ec.europa.eu/distribution/v2/countries/download/ref-countries-2013-01m.shp.zip" # location on the Eurostat website
download.file(url, basename(url), mode="wb") #download Eurostat country shapefiles
unzip("ref-countries-2013-01m.shp.zip") # unzip the boundary data
unzip("CNTR_RG_01M_2013_4326.shp.zip")

#load shapefiles
#communities
com <- st_read("COMM_RG_01M_2016_4326.shp", 
			  stringsAsFactors = FALSE) %>% 
  	   st_transform(4326) %>% 
       st_as_sf() %>%
       dplyr::filter(!CNTR_ID%in%"GL") #remove Greenland

#countries
states <- st_read("CNTR_RG_01M_2013_4326.shp", 
			  stringsAsFactors = FALSE) %>% 
  	   st_transform(4326) %>% 
       st_as_sf()

#only European countries (except those below) for border lines
out <- c("MA", "TN", "DZ", "EG", 
		 "LY", "JO", "IL", "PS", 
		 "SY", "SA", "LB", "IQ", 
		 "IR", "GL", "BY", "BA", 
		 "ME", "MD", "RU")
cn1 <- subset(states, !FID%in%out)

# extract Belarus, Bosnia-Herzegovina, Moldova, Montenegro and Russia
ins <- c("BY", "BA", "ME", "MD", "RU")
cn2 <- subset(states, FID%in%ins)   

#ANALYSIS
df  <- exact_extract(ras, com, "mean")
f <- cbind(com, df) %>% 
     st_as_sf()
names(f)[12] <- "values"

#LEGEND
# let's find a natural interval with quantile breaks
ni = classIntervals(f$values, 
	            n = 8, 
	            style = 'quantile')$brks
# this function uses above intervals to create categories
labels <- c()
for(i in 1:length(ni)){
    labels <- c(labels, paste0(round(ni[i], 0), 
                             "–", 
                             round(ni[i + 1], 0)))
}
labels <- labels[1:length(labels)-1]

# finally, carve out the categorical variable 
# based on the breaks and labels above
f$cat <- cut(f$values, 
              breaks = ni, 
              labels = labels, 
              include.lowest = T)
levels(f$cat) # let's check how many levels it has (8)

# label NAs, too
lvl <- levels(f$cat)
lvl[length(lvl) + 1] <- "No data"
f$cat <- factor(f$cat, levels = lvl)
f$cat[is.na(f$cat)] <- "No data"
levels(f$cat)

# MAPPING
# define projections
crsLONGLAT <- "+proj=longlat +datum=WGS84 +no_defs"
crsLAEA <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +datum=WGS84 +units=m +no_defs"
#create a bounding box
bb <- st_sfc(
  st_polygon(list(cbind(
    c(-10.6600, 35.00, 35.00, -10.6600, -10.6600), # x-coordinates (longitudes) of points A,B,C,D
    c(32.5000, 32.5000, 71.0500, 71.0500, 32.5000)     # y-coordinates (latitudes) of points A,B,C,D
    ))),
  crs = crsLONGLAT)
# tranform to Lambert projection
laeabb <- st_transform(bb, crs = crsLAEA)
b <- st_bbox(laeabb) #create a bounding box with new projection

map <- 
ggplot() +
geom_sf(data=f, aes(fill=cat), color=NA) +
geom_sf(data=cn1, fill="transparent", color="white", size=0.2) + #lines
geom_sf(data=cn2, fill="grey80", color="white", size=0.2) + #missing Euro countries
coord_sf(crs = crsLAEA, xlim = c(b["xmin"], b["xmax"]), ylim = c(b["ymin"], b["ymax"])) + 
labs(y="", subtitle="at community level",
         x = "",
         title="Fractional forest cover density in 2019",
         caption="©2021 Milos Popovic https://milospopovic.net\nSource: Buchhorn, M. et al. Copernicus Global Land Cover Layers — Collection 2.\nRemote Sensing 2020, 12, Volume 108, 1044. DOI 10.3390/rs12061044")+
scale_fill_manual(name= "average % forest cover",
  values=rev(c("grey80", '#1b3104', '#294d19', '#386c2e', 
  			  '#498c44', '#5bad5d', '#8dc97f', '#c4e4a7', 
  			  '#fefed3')),
  labels=c("0–6",     "6–10",    "10–15",   "15–21",   "21–29",   "29–39",   "39–52",  
			">52",   "No data"),
  drop=F)+
guides(fill=guide_legend(
            direction = "horizontal",
            keyheight = unit(1.15, units = "mm"),
            keywidth = unit(15, units = "mm"),
            title.position = 'top',
            title.hjust = 0.5,
            label.hjust = .5,
            nrow =1,
            byrow = T,
            #labels = labs,
            # also the guide needs to be reversed
            reverse = F,
            label.position = "bottom"
          )
    ) +
theme_minimal() +
theme(panel.background = element_blank(), 
legend.background = element_blank(),
legend.position = c(.45, .04),
panel.border = element_blank(),
panel.grid.minor = element_blank(),
panel.grid.major = element_line(color = "white", size = 0.2),
plot.title = element_text(size=22, color='#478c42', hjust=0.5, vjust=0),
plot.subtitle = element_text(size=18, color='#86cb7a', hjust=0.5, vjust=0),
plot.caption = element_text(size=9, color="grey60", hjust=0.5, vjust=10),
axis.title.x = element_text(size=10, color="grey20", hjust=0.5, vjust=-6),
legend.text = element_text(size=9, color="grey20"),
legend.title = element_text(size=10, color="grey20"),
strip.text = element_text(size=12),
plot.margin     =   unit(c(t=1, r=-2, b=-1, l=-2),"lines"), #added these narrower margins to enlarge maps
axis.title.y = element_blank(),
axis.ticks = element_blank(),
axis.text.x = element_blank(),
axis.text.y = element_blank())