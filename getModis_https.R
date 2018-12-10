#Write a small parameter file that is used by USGS's MODIS Reprojection
#Tool (MRT), then call the MRT "resample" routine, which reads the parameter
#file and does the image re-projection and/or cropping.
projectMODISjp <- function(fname='tmp.file',hdfName,output.name,MRTLoc,UL="",LR="",resample.method='NEAREST_NEIGHBOR',projection='GEO',
                           subset.bands='',parameters='0 0 0 0 0 0 0 0 0 0 0 0',datum='WGS84',utm.zone=NA,pixel_size){
#  From MRT manual: "HDF-EOS input files contain several layers of data, which
#  are called Science Data Sets (SDS). The term “SDS” is used interchangeably in
#  this document with the term “band.” Any subset of the input bands may be
#  selected for reprojection. The default is to reproject all input bands."
  
  #Write a parameter text file, line by line
  #stop("Starting projection")
  filename = file(fname, open="wt")
  write(paste('INPUT_FILENAME = ', getwd(), '/',hdfName, sep=""), filename) 
  if (subset.bands != '') {
    write(paste('SPECTRAL_SUBSET = ( ',subset.bands,' )',sep=''),filename,append=TRUE)
  }
  if (UL[1] != '' && LR[1] != '') {
    write('SPATIAL_SUBSET_TYPE = INPUT_LAT_LONG', filename, append=TRUE)
    #write('SPATIAL_SUBSET_TYPE = OUTPUT_PROJ_COORDS', filename, append=TRUE)
    write(paste('SPATIAL_SUBSET_UL_CORNER = ( ', as.character(UL[1]),' ',as.character(UL[2]),' )',sep=''), filename, append=TRUE)
    write(paste('SPATIAL_SUBSET_LR_CORNER = ( ', as.character(LR[1]),' ',as.character(LR[2]),' )',sep=''), filename, append=TRUE)
  }
  write(paste('OUTPUT_FILENAME = ', output.name, sep=""), filename, append=TRUE)
  write(paste('RESAMPLING_TYPE = ',resample.method,sep=''), filename, append=TRUE)
  write(paste('OUTPUT_PROJECTION_TYPE = ',projection,sep=''), filename, append=TRUE)
  write(paste('OUTPUT_PROJECTION_PARAMETERS = ( ',parameters,' )',sep=''), filename, append=TRUE) #see Appendix C of MRT manual for details
  write(paste('DATUM = ',datum,sep=''), filename, append=TRUE)
  if (projection == 'UTM') write(paste('UTM_ZONE = ',utm.zone,sep=''), filename, append=TRUE)
  if(!is.na(pixel_size)){
    write(paste('OUTPUT_PIXEL_SIZE = ',as.character(pixel_size),sep=''), filename, append=TRUE)
  }
  close(filename)
  #Finally, call the MODIS Reprojection Tool "resample" routine
  e <- system(paste(MRTLoc, '/resample -p ',getwd(),'/',fname, sep=''))
  e
}

#Main function. Download, mosaic, crop, subset, and reproject MODIS hdf files, 
#and convert them to other formats (e.g., geoTIFF). Relies on the USGS MODIS
#Rrojection Tool (MRT), which must be installed separately. Download MRT from
#LPDAAC here: https://lpdaac.usgs.gov/tools/modis_reprojection_tool.
#Requires the rvest and httr R libraries.
# Explanation of parameters:
#   FTP or dataURL: URL of the server containing MODIS data
#   h: horizontal tile identifier
#   v: vertical tile identifier
#   dates: dates in YYYY.MM.DD format
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
#   utm.zone: UTM zone of the reprojection (see MRT documentation).  The program will pick a zone if not entered.
#   pixel_size: pixel size of the output data in meters(UTM) or degrees (GEO: 0.0045 degrees roughly equals 500m)
#Example: tile numbers for the western Gobi are H=24, V=4; for the southern Gobi they are H=c(25, 26), V=4.  
#Tile numbers can be figured out by going to https://search.earthdata.nasa.gov/search?q=MOD10A2, selecting 
#spatial filters (using one of several available methods), choosing a short time window to make it more
#obvious, and then inspecting the metadata for the "granules" that are suggested, which you can do 
#without actually downloading them.  
GetMODIS_https <- function(dataURL,user='',passwd='',h,v,image_dates,mosaic=T,MRTLoc,subset.bands='',del=T,proj=T,UL="",LR="",resample.method='NEAREST_NEIGHBOR',projection='GEO', parameters='0 0 0 0 0 0 0 0 0 0 0 0',datum='WGS84',utm.zone=NA,pixel_size=NA,download=T) {
  if (strsplit(dataURL,'')[[1]][length(strsplit(dataURL,'')[[1]])] != "/") dataURL <- paste(dataURL,"/",sep="") #Add a slash to the end of the dataURL address if necessary

  #Request list of folder names (sample: "2000.02.24" "2000.02.26" "2000.03.05" "2000.03.06" "2000.03.13", etc.)
  #from NSIDC server.
  tryCatch({
    print("Requesting folder list")
   response <- httr::GET(dataURL, authenticate(user, passwd),timeout(60))
   stop_for_status(response)
  }, http_error=function(e) {
    stop("Server is not responding.  Please try later.")
  })

  #Convert response to html
  rhtml<-read_html(response)
  
  #Check to see whether the directories are in a table (they are for NSIDC)
  #TODO: This could be a customized list for various data sources that matches
  #whatever HTML structure their pages have.  This version is very fragile (and
  #is repeated about 60 lines below here.
  #1. NSIDC
  if(length(html_nodes(rhtml,"table")) > 0){
    #Get the first table on the page (which should be the directory structure), as a dataframe
    dir_table<-html_table(html_nodes(rhtml,"table"))[[1]] 
    #Get the directories as a vector of characters and remove the slash
    dirs<-dir_table$Name[-1]
  #2. MODIS NDVI
  } else if(length(html_nodes(rhtml,"a")) > 0){
    dirs<-html_nodes(rhtml,"a")
    dirs<-html_attr(dirs,name="href") #Get just the href portion of the links
  }
  
  #Remove the slash from the directory names
  dirs<-gsub("/", "", dirs)
  #Convert to dates
  dates<-data.frame(dirs,as.Date(gsub("\\.","-",dirs),format="%Y-%m-%d"))
  names(dates)<-c("date_string","date")
  #Discard all non-dates
  dates<-dates[!is.na(dates$date),]
  
  #Get start and end dates
  if (length(image_dates) > 1) {
    start.date <- as.Date(image_dates[1],format="%Y-%m-%d")
    end.date <- as.Date(image_dates[2],format="%Y-%m-%d")
  }
  
  #Select just the dates we want
  dates<-dates[dates$date >= start.date & dates$date <= end.date,]
  if (nrow(dates) < 1) {
    stop("There are no data available on the server for the chosen dates.")
  } else {
    #Keep the date_string that matches folder names on the server (careful that it's not a factor)
    dirs<-as.character(dates$date_string)
  }
  
  #MAIN LOOP: Loop through the directories we chose, download files and call MRT to mosaic them if required
  for (i in 1:length(dirs)) {
    all_files_list <- 0
    pageURL<-paste0(dataURL,dirs[i],"/")
    #Request list of files in the directory from NSIDC server.
    tryCatch({
      print("Requesting list of files")
      response <- httr::GET(pageURL, authenticate(user, passwd),timeout(60))
      stop_for_status(response)
    }, http_error=function(e) {
      stop("Server is not responding.  Please try later.")
    })
    
    rhtml<-read_html(response)
    
    #TODO: This could be a customized list for various data sources that matches
    #whatever HTML structure their pages have.  This version is very fragile.
    #1. NSIDC
    if(length(html_nodes(rhtml,"table")) > 0){
      #Get the first table on the page (which should be the directory structure), as a node list
      file_table<-html_table(html_nodes(rhtml,"table"))[[1]] 
      #Get the directories as a vector of characters and remove the slash
      all_files_list<-file_table$Name[-1]
      #2. MODIS NDVI
    } else if(length(html_nodes(rhtml,"a")) > 0){
      all_files_list<-html_nodes(rhtml,"a")
      all_files_list<-html_attr(all_files_list,name="href") #Get just the href portion of the links
    }

    #Select the tiles we want from one directory into "hdf_filelist"
    hdf_filelist <- c()
    for (vv in v) {
      for (hh in h) {
        #left-pad tile numbers with zeros
        vc<-sprintf("%02.0f",vv) 
        hc<-sprintf("%02.0f",hh)
        #Find files that match the pattern "*h26v04*.hdf", for example
        hdf_file <- grep(".hdf$",grep(paste('h',hc,'v',vc,sep=''),all_files_list,value=TRUE),value=TRUE)
        if (length(hdf_file) == 1) hdf_filelist <- c(hdf_filelist,hdf_file)
      }
    }
    
    hdf_filelist<-unique(hdf_filelist) #drop any duplicate names 
    
    #Download the hdf files in the directory and write them to the working directory
    if (length(hdf_filelist) > 0) {
      n.downloaded<-0
      if(download==T){
        for (hdf_file in hdf_filelist) {
          tryCatch({
            #Download the hdf file
            fileURL<-paste0(pageURL,hdf_file)
            print(paste("Downloading",hdf_file))
            response <- httr::GET(fileURL, authenticate(user, passwd),timeout(60))
            stop_for_status(response)
          }, http_error=function(e) {
            stop("Server is not responding.  Please try later.")
          })
          
          # Create a filename for the hdf file
          outfile = file ( paste(getwd(),'/',hdf_file,sep=""), open="wb")
          #Write to the file
          bin <- content(response, "raw")
          writeBin(object=bin, con=outfile)
          close(outfile)
          #print(paste(hdf_file,"successfully downloaded."))
          n.downloaded<-n.downloaded + 1
        }# for hdf_file in hdf_filelist
        print(paste("Image date ",dirs[i],": ",n.downloaded," files downloaded.",sep=''))
      }#if downloading files
      
      #Write a temporary file for MRT to use
      #Create a date string for use in output filenames
      date_name <- sub(sub(pattern="\\.", replacement="_", dirs[i]), pattern="\\.", replacement="_", dirs[i])
      if (length(hdf_filelist) > 1 && mosaic){
        #Open a temporary file in the working directory and write the names of the files to be mosaiced in it as text.
        mosaicname = file(paste(getwd(), "/temporary.mosaic.prm", sep=""), open="wt")
        write(paste(getwd(),"/",hdf_filelist[1], sep=""), mosaicname)
        for (j in 2:length(hdf_filelist)) {
          write(paste(getwd(),"/",hdf_filelist[j], sep=""),mosaicname,append=T)
        }
        close(mosaicname)
        
        #SEE MRT User's Manual "Mosaic Tool" section - many important caveats. 
        #NOTE: Only input Sinusoidal and Integerized Sinusoidal projections are supported for mosaicking.
        #MRT syntax: mrtmosaic -i input_filenames_file -t -h -o output_filename
        #-t is to specify tiles, -h is to mosaic just headers
        #-s specifies the spectral_subset ["b1 b2 ... bN"]; should be 0 or 1 for each band
        #output must be an hdf file.  input must be a .prm file
        #Check to make sure that we didn't erase the hdf files by mistake
        if(download==F){
          for (j in 1:length(hdf_filelist)) {
            thefile<-paste0(getwd(),"/",hdf_filelist[j])
            if(!file.exists(thefile)){
              stop("File",thefile,"is missing and cannot be mosaiced (if Del=T it may have been erased.)")
            }
          }
        }
        if(download==T && n.downloaded > 1){
          #Mosaic the images using MRT (either all bands, or just selected bands)
          if (subset.bands[1] != '') {
            e <- system(paste(MRTLoc, '/mrtmosaic -i ', getwd(), '/temporary.mosaic.prm -s "',subset.bands,'" -o ',getwd(), '/Mosaic_',date_name,'.hdf', sep=""))
            if (e != 0) print ("Mosaic failed! 'subset.bands' may have incorrect structure!")
          } else {
            infile.list<-paste(getwd(), '/temporary.mosaic.prm',sep="")
            outfile<-paste(getwd(), '/Mosaic_',date_name,'.hdf',sep="")
            
            #Call MRT to mosaic the files
            comstring<-paste(MRTLoc, "/mrtmosaic -i ", infile.list, " -o ", outfile, sep="")
            if(download){
              e <- system(comstring)
            } else{
              e<-0
              print("Files not downloaded")
            }
            
            #Alternative 1: 
            #e <- system2(command=paste(MRTLoc, "/mrtmosaic",sep=""),args=(paste("-i ",getwd(), "/temporary.mosaic.prm -o ",getwd(),"/Mosaic_",date_name,".hdf", sep="")))
            
            #Alternative 2: use GDAL (works, but is very slow compared to MRT)
            #define some filenames
            #outfile.virt<-paste(getwd(), '/Mosaic_',date_name,'.virt',sep="")
            #outfile.tif<-paste(getwd(),'/Mosaic_',date_name,'.tif',sep="")
            #call the GDAL routines to first create a virtual mosaic, then convert it to tiff
            #gdalbuildvrt(input_file_list = infile.list,output.vrt=outfile.virt) #-te <x_min> <y_min> <x_max> <y_max>
            #gdal_translate(src_dataset=outfile.virt, dst_dataset=outfile.tif, of="GTiff")  
            
            if(e==0){
              print(paste("Mosaic created for",length(hdf_filelist),"files on",date_name,"."))
            } else{
              print (paste("Mosaic FAILED for",length(hdf_filelist),"files on",date_name,"."))
            }
          }
          #Delete unneeded files if requested
          if (del) for (hdf_file in hdf_filelist) unlink(paste(getwd(), '/', hdf_file, sep=""))
        } else print(paste("Warning:",n.downloaded,"files downloaded on",date_name)) #if downloaded > 1
      } #if mosaic and length(modislist)>1
      
      #Now re-project the files if called for (calls ProjectMODIS())
      #if (proj && file.exists(hdf_file))
      if (proj) {
        pref <- strsplit(hdf_file,'\\.')[[1]][1]
        if (mosaic) e <- projectMODISjp('parameter.file',hdfName=paste('Mosaic_',date_name,'.hdf',sep=''),output.name=paste(pref,'_',date_name,'.tif',sep=''),MRTLoc=MRTLoc,UL=UL,LR=LR,projection=projection,parameters=parameters,utm.zone=utm.zone,pixel_size=pixel_size)
        else {
          if (subset.bands == '') e <- projectMODISjp('parameter.file',hdfName=hdf_file,output.name=paste(pref,'_',date_name,'.tif',sep=''),MRTLoc=MRTLoc,UL=UL,LR=LR,projection=projection,parameters=parameters,utm.zone=utm.zone,pixel_size=pixel_size)
          else e <- projectMODISjp('parameter.file',hdfName=hdf_file,output.name=paste(pref,'_',date_name,'.tif',sep=''),MRTLoc=MRTLoc,subset.bands=subset.bands,UL=UL,LR=LR,projection=projection,parameters=parameters,utm.zone=utm.zone,pixel_size=pixel_size)
        }
        if (e != 0)  print ("reprojection Failed!")
        if (del && mosaic) unlink(paste('Mosaic_',date_name,'.hdf',sep=''))
        else {if(del) unlink(hdf_file)}
      }
    } #else print(paste("There is no imagery on the server for the selected tiles in ",dirs[i], sep=""))
  }#for i in length(dirs)
}# function GetMODIS_https


