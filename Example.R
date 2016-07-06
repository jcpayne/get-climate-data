require(RCurl)
setwd("/yourworkingdirectory") #This is where your output will be put
source(paste(getwd(),"/","getMODISv2.R",sep=""))
SNOWdaily<-"ftp://n5eil01u.ecs.nsidc.org/SAN/MOST/MOD10A1.005/" #MODIS daily snow cover 500m grid version 5 data

#Main function call

GetMODISjp(FTP = SNOWdaily,h=c(25,26),v=4,dates=c('2013.08.20','2013.08.20'),MRTLoc="/Applications/MRT/bin", subset.bands="1 1 0 0",projection="GEO",parameters="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0",datum="WGS84",UL=c(46,103),LR=c(41.5,113.5),del=F)

# Explanation of the parameters:
#   FTP: URL of the FTP server containing MODIS data
#   h: horizontal tile identifier
#   v: vertical tile identifier
#   dates: start and end dates, in the format "YYYY.MM.DD"
#   mosaic: whether to mosaic the downloaded files (T/F)
#   MRTLOC:  Location of the MODIS Reprojection Tool (MRT)
#   subset.bands: subset parameters (specify UL/LR, see below)
#   del: do you want to delete the original hdfs after processing (T/F)?
#   proj: do you want to project the data (T/F)
#   UL: upper left corner of the subset(see MRT documentation) in output projection
#   LR: lower right corner of the subset in output projection
#   resample.method: desired resampling method (IMPORTANT: must use 'NEAREST_NEIGHBOR' (the default) when numerical data are categorical (not continuous) --see MRT documentation.)
#   projection: desired projection (e.g., UTM or GEO; see MRT documentation)
#   parameters: output projection parameters: see Appendix C of MRT documentation
#   datum: datum of the reprojection (e.g. WGS84; see MRT documentation)
#   utm.zone: UTM zone of the reprojection (see MRT documentation)
#   pixel_size: pixel size of the output data in meters(UTM) or degrees (GEO: 0.0045 degrees roughly equals 500m)
