Download and process MODIS data (see Wiki tab for more detail)
===============================
This R function is designed to automatically download MODIS satellite data for a given range of dates and tiles, and to mosaic, clip, reproject and transform them.  It saves disk space by downloading the requested tiles for each date, performing the operations, and then discarding the original tiles (hdf files) if directed.  

Many government satellite data websites present data using the same by-date directory structures and hdf file formats.  However, those websites are not totally consistent in how they present data.  For example, EarthData.gov, which is a major aggregator of satellite data, used to allow download of MODIS data via anonymous FTP, but now users must create a user account with EarthData.gov and access data via https (see MODIS_example.R). Unfortunately, the USGS currently presents MODIS NDVI (vegetation index) datasets as a HTML page of *images with embedded links*, whereas the NSIDC presents MODIS snow cover data as *entries in an HTML table*.  That kind of whimsical, minor variation by government web programmers can easily break a custom script like this.  Ideally, all data services would use the same API, which would make getting data easy and reliable.  In reality, a whole suite of different APIs is being developed, and even so, most datasets are not yet available by API [example](https://nsidc.org/api/opensearch/).  The variation between government sites makes this script fragile, but with some modification the basic idea should work for many sites.   

In brief, the main function does this:
```
- Get a list of directories (which are organized by date)
- Prune the list to the dates requested
- For each directory (i.e., date):
	- Download the tiles requested
	- Mosaic them if requested 
	- Re-project and clip them if requested
	- Transform the file type (e.g., from hdf to geotiff) if requested
	- Discard the originals if requested
```
It writes the finished files into your R working directory by default, and will also create three tiny parameter files that are fed to MRT; these can be deleted at any time.


Installation
------------
The getModis_https.R file includes three R functions that must be sourced (see MODIS_example.R).  

The USGS's Modis Reprojection Tool, [MRT](https://lpdaac.usgs.gov/tools/modis_reprojection_tool) must be installed.  MRT is a command-line tool that does the mosaicing, re-projection and transformation.  MRT is a bit finicky to install on a Mac (see [here](http://stackoverflow.com/questions/37604466/r-system-not-working-with-modis-reprojection-tool/37646625#37646625)) and is limited in its options, but it is **exceedingly fast** compared to all other alternatives that I've tried, especially if you stick to the geographic projection (GEO).  See Appendix 3 of the MRT documentation for details on projection parameters.

Troubleshooting
--------------- 
1. MRT is picky about input parameters--check the MRT manual carefully if you are getting error messages about mosaicing or re-projecting.  
2. If you are not sure about the structure of your hdf file, try using HDFView (https://www.hdfgroup.org/products/java/release/download.html).  Note that some MODIS files are in HDF4 format, not HDF5, and some of the newer HDF viewers won't display HDF4 files correctly.  In HDFView, you can expand the tree on the left to get an idea of your file structure.

Disclaimer
--------------
This is an alpha version, but it worked for me and it's extensively commented to make it easier to modify.  

Attribution
-----------
This script was originally adapted from http://www.hakimabdi.com/20120411/download-and-process-modis-data-with-r/, which was designed for FTP. 

License
-------
The tools in this repository are free software; you can redistribute them and/or modify them under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.   
