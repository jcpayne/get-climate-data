Download and process MODIS data (see Wiki tab for more detail)
===============================
This R function is designed to automatically download MODIS satellite data for a given range of dates and tiles, and to mosaic, clip, reproject and transform them.  It saves space by downloading the requested tiles for each date, performing the operations, and then discarding the original tiles (hdf files) if directed.  Many government satellite data sites use the same by-date directory structure and hdf file format, and it should work for those sites as well, possibly with a bit of modification.  MODIS data used to be available by anonymous FTP, but you now have to create a user account with EarthData.gov and access to data is done via https (see MODIS_example.R).  My script is adapted from http://www.hakimabdi.com/20120411/download-and-process-modis-data-with-r/, which was designed for FTP.  

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
It writes the finished files into your R working directory by default, and will also create a few small parameter files that are fed to MRT; these can be deleted at any time.


Installation
------------
The getModis_https.R file includes three R functions that must be sourced (see MODIS_example.R).  

The USGS's Modis Reprojection Tool, MRT (https://lpdaac.usgs.gov/tools/modis_reprojection_tool) must be installed.  MRT is a command-line tool that does the mosaicing, re-projection and transformation.  MRT is a bit finicky to install on a Mac (see http://stackoverflow.com/questions/37604466/r-system-not-working-with-modis-reprojection-tool/37646625#37646625) and is limited in its options, but it is exceedingly fast compared to other alternatives that I've tried, especially if you stick to the geographic projection (GEO).  

Troubleshooting
--------------- 
1. MRT is picky about input parameters--check the MRT manual carefully if you are getting error messages about mosaicing or re-projecting.  
2. If you are not sure about the structure of your hdf file, try using HDFView (https://www.hdfgroup.org/products/java/release/download.html).  Note that some MODIS files are in HDF4 format, not HDF5, and some of the newer HDF viewers won't display HDF4 files correctly.  In HDFView, you can expand the tree on the left to get an idea of your file structure.

Disclaimer
--------------
This is an alpha version, but it worked for me and it's extensively commented, to make it easier to modify.

License
-------
The tools in this repository are free software; you can redistribute them and/or modify them under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.   
