Download and process MODIS data
===============================
This R function is designed to automatically download MODIS satellite data for a given range of dates and tiles, and to mosaic, clip, reproject and transform them.  It is adapted from Hakim Abdi's script, at http://www.hakimabdi.com/20120411/download-and-process-modis-data-with-r/.  I used it for downloading files from the National Snow and Ice Data Center, and in the process I solved some R and OSX problems that prevented the original from working for me.  Many government satellite data sites use the same by-date directory structure and hdf file format, and it should work for those sites as well, possibly with a bit of modification.  

In brief, the main function does this:
```
- Get a list of directories (which are organized by date)
- Prune the list to the dates requested
- For each directory (i.e., date):
	- Download the tiles requested
	- Mosaic them if requested 
	- Re-project and clip them if requested
	- Transform the file type if requested
	- Discard the originals if requested
```
It writes the finished files into your R working directory by default, and will also create a few small parameter files that are fed to MRT.  They can be deleted at any time.


Installation
------------
The getModisv2.R file includes three R functions that must be sourced (run) before running the Example.R file.  

In addition, the USGS's Modis Reprojection Tool, MRT (https://lpdaac.usgs.gov/tools/modis_reprojection_tool) must be installed for the script to work.  MRT is a command-line tool that does the mosaicing, re-projection and transformation.  MRT is a bit finicky to install on a Mac (see http://stackoverflow.com/questions/37604466/r-system-not-working-with-modis-reprojection-tool/37646625#37646625) and limited in its options, but is exceedingly fast compared to other alternatives that I've tried, especially if you stick to the geographic projection (GEO).  

Troubleshooting
--------------- 
1. If you are looking for a single date for a product that spans several dates (such as an 8-day summary), one end or other of your date range must lie on the date of the available product, or the function won't find anything. Also, for snow data at least, the latest version 6 is currently (Jul 2016) missing some dates, whereas version 5 is complete.
2. MRT is picky about input parameters--check the MRT manual carefully if you are getting error messages about mosaicing or re-projecting.  
3. If you are not sure about the structure of an hdf file, try using HDFView, at https://www.hdfgroup.org/products/java/release/download.html.  Note that some MODIS files are in HDF4 format, not HDF5, and some of the newer HDF viewers won't display HDF4 files correctly.  In HDFView, you can expand the tree on the left to get an idea of your file structure.
4.  See http://stackoverflow.com/questions/37713293/how-to-circumvent-ftp-server-slowdown/37845842#37845842 for issues I ran into with the ftp call.

Disclaimer
--------------
This is a not-even-alpha version and far from elegant, but it worked for me.  Feel free to fork/modify/improve.  I commented it extensively in my efforts to understand the original.


License
-------
The tools in this repository are free software; you can redistribute them and/or modify them under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.   
