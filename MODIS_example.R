#1. Put the getMODIS_https.R file in your working directory and source it.  By default, your output will also go in your working directory.
source("getMODIS_https.R")

#2. If you don't have them already, install the httr library, which is used for https communications, 
#and the rvest library, which is used for reading html.
#install.packages("httr")
#install.packages("rvest")
library(httr)
library(rvest)

#3. Record the URL for the MODIS server's top-level data directory, for the product you want
MOD10A1_URL<-"https://n5eil01u.ecs.nsidc.org/MOST/MOD10A1.006/" #Example: this is the MODIS daily snow cover 500m grid version 6 data

#4. If you haven't already, sign up with EarthData.gov (https://urs.earthdata.nasa.gov/users/new), and use 
#the web browser to figure out which tiles you want (select a product, select a single date, select your study area 
#on the map with one of their tools (you can draw polygons, etc.), and then "view granules").

#5. Modify this function call; fill in your username and password, tile numbers and dates, and run it to get the tiles and dates you want.
GetMODIS_https(dataURL=MOD10A1_URL,user="your_username",passwd="your_password",h=c(25,26),v=4,image_dates=c('2017-06-05','2017-06-18'),mosaic=T,MRTLoc="/Applications/MRT/bin",subset.bands="1 0 0 0",del=T,proj=T,UL=c(46,103),LR=c(41.5,113.5),resample.method='NEAREST_NEIGHBOR',projection='GEO', parameters="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0",datum='WGS84',utm.zone=NA,pixel_size=NA,download=T)

#That's all there is to it.

# Explanation of the parameters:
#   dataURL: URL of the MODIS data server
#   h: horizontal tile(s) identifier
#   v: vertical tile(s) identifier
#   dates: start and end dates, in the format "YYYY-MM-DD"
#   mosaic: whether to mosaic the downloaded files (T/F)
#   MRTLOC:  Location of the MODIS Reprojection Tool (MRT) program
#   subset.bands: MRT can take a subset of the bands in the image.  Have a look at your hdf file structure to make sure you're getting the variable(s) you want.
#	del: do you want to delete the original hdf files after processing?
#   proj: do you want to project the data (T/F)
#   UL: upper left corner of the area you want (see MRT documentation) in output projection units
#   LR: lower right corner of the area you want in output projection units
#   resample.method: desired resampling method (IMPORTANT: you must use 'NEAREST_NEIGHBOR' (the default) when numerical data are categorical (not continuous) --see MRT documentation.)
#   projection: desired projection (e.g., UTM or GEO; see MRT documentation)
#   parameters: output projection parameters: see Appendix C of MRT documentation
#   datum: datum of the reprojection (e.g. WGS84; see MRT documentation)
#   utm.zone: UTM zone of the reprojection (see MRT documentation)
#   pixel_size: pixel size of the output data in meters(UTM) or degrees (GEO: 0.0045 degrees roughly equals 500m)
