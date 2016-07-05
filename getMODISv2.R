#This file is adapted from Hakim Abdi's script, at http://www.hakimabdi.com/20120411/download-and-process-modis-data-with-r/

#This function writes a parameter file, then calls the MRT "resample" routine, which reads that parameter file
#and does the image re-projection and/or cropping.
projectMODISv2 <- function(fname='tmp.file',hdfName,output.name,MRTLoc,UL="",LR="",resample.method='NEAREST_NEIGHBOR',projection='UTM',
                         subset.bands='',parameters='0 0 0 0 0 0 0 0 0 0 0 0',datum='WGS84',utm.zone=NA,pixel_size){
  #Write a parameter text file, line by line
    filename = file(fname, open="wt")
  write(paste('INPUT_FILENAME = ',hdfName, sep=""), filename) 
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
  write(paste('OUTPUT_PROJECTION_PARAMETERS = ( ',parameters,' )',sep=''), filename, append=TRUE)
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

#mosaicMODISjp() mosaics the files in a directory, using the Modis Reprojection Tool (MRT).
#It places a mosaiced hdf file in the user's R working directory, and optionally deletes the original hdf tiles.
#It returns the name of the mosaiced file (no filepath).
#SEE MRT User's Manual "Mosaic Tool" section - many important caveats. 
#NOTE: Only input Sinusoidal and Integerized Sinusoidal projections are supported for mosaicking.
#MRT syntax: mrtmosaic -i input_filenames_file -t -h -o output_filename
#-t is to specify tiles, -h is to mosaic just headers
#-s specifies the spectral_subset ["b1 b2 ... bN"]; should be 0 or 1 for each band
#output must be an hdf file.  input must be a .prm file
mosaicMODISv2 <- function(MRTLoc,Modislist,subset.bands='',delete.hdf.originals=F,outfile=''){
  #Check to make sure that the file list and files exist
  if (is.na(Modislist) || length(Modislist) < 1){
    stop("Missing the list of files to mosaic.")
  }
  for (j in 1:length(Modislist)) {
    thefile<-paste(getwd(),"/",Modislist[j],sep="")
    if(!file.exists(thefile)){
      stop("File",thefile,"is missing and cannot be mosaiced (if del=T, it may have been erased.)")
    }
  }
  if(outfile==''){
    stop("Output filename is missing for mosaic operation")  
  }
  
  infile.list<-paste(getwd(), '/temporary.mosaic.prm',sep="")
  
  #Call MRT to mosaic the files (syntax is harder if subset.bands is not empty)
  if (subset.bands[1] != '') {
    #Alternative - this also works: comstring<-paste(MRTLoc, '/mrtmosaic -i ',getwd(), '/temporary.mosaic.prm -s "',subset.bands, '" -o ',outfile, sep="")
    comstring<-paste(MRTLoc, '/mrtmosaic -i ',infile.list, ' -s "',subset.bands, '" -o ',outfile, sep="")
    e <- system(comstring)
    if (e != 0) print ("Mosaic failed! 'subset.bands' may have incorrect structure!")
  } else {
    comstring<-paste(MRTLoc, "/mrtmosaic -i ", infile.list, " -o ", outfile, sep="")
    e <- system(comstring)
  }#subset.bands is empty
  
  if(e==0){
    print(paste("Mosaic created for",length(Modislist),"files. Mosaiced file:",outfile,"."))
    #Delete unneeded files if requested
    if (delete.hdf.originals) {
      for (ModisName in Modislist) {
        unlink(paste(getwd(), '/', ModisName, sep=""))
      }
    }#if delete.hdf.originals
    return(outfile)
  } else{
    print (paste("Mosaic FAILED for",length(Modislist),"files:"))
    print(Modislist)
    return(NA)
  }
} #function(mosaicMODISjp)

GetMODISv2 <- function(FTP,h,v,dates,mosaic=T,MRTLoc,subset.bands='',del=T,proj=T,UL="",LR="",resample.method='NEAREST_NEIGHBOR',projection='UTM', parameters='0 0 0 0 0 0 0 0 0 0 0 0',datum='WGS84',utm.zone=NA,pixel_size=NA) {
  if (strsplit(FTP,'')[[1]][length(strsplit(FTP,'')[[1]])] != "/") FTP <- paste(FTP,"/",sep="") #Add a slash to the end of the FTP address if necessary
  items <- 0
  class(items) <- "try-error"  #Set the class to "try-error" by default
  ce <- 0
  while(class(items) == "try-error") {
    #Get a list of items in the directory (returns ALL filenames)
    if(url.exists(FTP)){
      curl=getCurlHandle()
      items <- try(strsplit(getURL(url=FTP,curl=curl), "\r*\n")[[1]],silent=FALSE) 
      rm(curl)
      gc()
    } else{
      print(paste("URL does not exist:",FTP))
    }
    if (class(items) == "try-error") {
      Sys.sleep(30)
      ce <- ce + 1
      if (ce == 42) stop("The FTP server is not responding. Please try again later.") #stop after 21 mins
    }
  } #While (trying to connect with URL)
  items <- items[-1] #remove the first item, which is just a total
  
  #Get a (typically long) list of folder names ("2000.02.24" "2000.02.26" "2000.03.05" "2000.03.06" "2000.03.13", etc.)
  dirs <- unlist(lapply(strsplit(items, " "), function(x){x[length(x)]}))

  #Discard a few directories whose names begin with "DPRecentInserts"
  todrop<-c()
  todrop<-grep("DPRecentInserts",dirs)
  if (length(todrop) > 0) {
    dirs<-dirs[-todrop]
  }

  #Check the directory name formats and warn about invalid dates
  namesOK<-TRUE 
  for (i in 1:length(dirs)) {
     d <- unlist(strsplit(dirs[i],"\\.")) #the directory name, split into 3 components (year, month, day)
     #Check that there are three components to the directory name (should be year, month, day)
     if(length(d) < 3) {
       print(paste("Bad directory name: ",dirs[i]))
       namesOK<-false
     }
     #If there are at least 3 components, check to make sure that the date is in the format we expect 
     else {
         #Turn the directory name into a date string
         dt<-d[1]
         for (j in 2:length(d)){
            dt<-paste(dt,d[j],sep="-")
         }
        #Check to make sure that the date format is valid (as.Date returns NA if not)
        if(is.na(as.Date(dt,format="%Y-%m-%d"))){
           namesOK<-FALSE
           print(paste("Bad directory name: ",dirs[i]))
        } #date format is valid
      }#directory name has at least 3 components
    } #for 1: length(dirs)
    if(!namesOK){stop("Error: Directory name(s) do not match expected year.month.day pattern")}
  
  #Get start and end dates as split strings
  if (length(dates) > 1) {
    start.date <- strsplit(dates[1],'\\.')[[1]]
    end.date <- strsplit(dates[2],'\\.')[[1]]
  }

    #Loop through the directory list (dirs), keeping only those which have the desired years in a temporary list (wr)
    wr <- c()
    for (i in 1:length(dirs)) {
      d <- unlist(strsplit(dirs[i],"\\.")) #the directory name, split into 3 components (year, month, day)
      if (length(d) == 3)
        if (as.numeric(d[1]) >= as.numeric(start.date[1]) && as.numeric(d[1]) <= as.numeric(end.date[1]) ) wr <- c(wr,i)
    }
    if (length(wr) > 0) dirs <- dirs[wr]
    if(length(dirs) < 1) {stop("There are no data available on the server for the chosen years.")}
    
    #Discard months that are out of range in the desired years
    wr <- c() #reset the temporary list
    for (i in 1:length(dirs)) {
      d <- unlist(strsplit(dirs[i],"\\."))
      if (as.numeric(d[2]) < as.numeric(start.date[2]) && as.numeric(d[1]) == as.numeric(start.date[1])) wr <- c(wr,i)
      if (as.numeric(d[2]) > as.numeric(end.date[2]) && as.numeric(d[1]) == as.numeric(end.date[1])) wr <- c(wr,i)
    }
    if (length(wr) > 0) {dirs <- dirs[-wr]}
    if(length(dirs) < 1) {stop("There are no data available on the server for the chosen years and months.")}
        
    #Discard days that are out of range
    wr <- c() #reset the temporary list
    for (i in 1:length(dirs)) {
      d <- unlist(strsplit(dirs[i],"\\."))
      if (as.numeric(d[3]) < as.numeric(start.date[3]) && as.numeric(d[1]) == as.numeric(start.date[1]) && as.numeric(d[2]) == as.numeric(start.date[2])) wr <- c(wr,i)
      if (as.numeric(d[3]) > as.numeric(end.date[3]) && as.numeric(d[1]) == as.numeric(end.date[1]) && as.numeric(d[2]) == as.numeric(end.date[2])) wr <- c(wr,i)
    }
    if (length(wr) > 0) {dirs <- dirs[-wr]}
  
    if (length(dirs) < 1) stop("There are no data available on the server for the chosen dates.")

    print("Files from the following directories are being downloaded:")
    print(dirs)
    
  #MAIN LOOP: Loop through the directories we chose, download files and call MRT to mosaic them if required
  for (i in 1:length(dirs)) {
    getlist <- 0
    class(getlist) <- "try-error"
    ce <- 0
    #Get a list of all available tiles on the selected date
      while(class(getlist) == "try-error") {
      theurl<-paste(FTP,dirs[i], "/", sep="")
      if(url.exists(theurl)){
        curl<-getCurlHandle()
        getlist <- try(strsplit(getURL(url=theurl,curl=curl), "\r*\n")[[1]],silent=FALSE)
        rm(curl)
        gc()
      } else print(paste("URL does not exist:",FTP))
      if (class(getlist) == "try-error") {
        Sys.sleep(30)
        ce <- ce + 1
        if (ce == 42) stop("The FTP server is not responding. Please try again later.")
      }#if error
    }#while error

    #Select the tiles we want from one directory into "Modislist"
    #Modislist usually contains one or more tiles for a *single* date
    getlist <- getlist[-1]
    getlist <- unlist(lapply(strsplit(getlist, " "), function(x){x[length(x)]}))
    Modislist <- c()
    for (vv in v) {
      for (hh in h) {
        if (vv < 10) vc <- paste('0',as.character(vv),sep='')
        else vc <- as.character(vv)
        if (hh < 10) hc <- paste('0',as.character(hh),sep='')
        else hc <- as.character(hh)
        #Find files that match the pattern "*h26v04*.hdf" as example
        ModisName <- grep(".hdf$",grep(paste('h',hc,'v',vc,sep=''),getlist,value=TRUE),value=TRUE)
        if (length(ModisName) == 1) Modislist <- c(Modislist,ModisName)
      }
    }
    Modislist<-unique(Modislist) #get rid of duplicate names 
    
    #Download the files in Modislist
    if (length(Modislist) > 0) {
      n.downloaded<-0
      for (ModisName in Modislist) {
        er <- 0
        class(er) <- "try-error"
        ce <- 0
        starttrying<-Sys.time()
          while(class(er) == "try-error") {
            theurl<-paste(FTP,dirs[i], "/",ModisName,sep="")
            #print(paste("Trying URL:",theurl))
            if(url.exists(theurl)) {
              curl<-getCurlHandle()
              er<-try(getBinaryURL(url=theurl,curl=curl),silent=FALSE)
              rm(curl)  # release the curl!
              gc() #garbage collection, to force it to remove the curl
            } else print(paste("URL does not exist:",theurl))
            if (class(er) == "try-error") {
              Sys.sleep(30)
              ce <- ce + 1
              mins<-as.numeric(Sys.time() - starttrying) %/% 60 #the modulus
              secs<-as.integer(as.numeric(Sys.time() - starttrying)) %% 60 #the remainder
              print(paste("Try: ",ce,"; Elapsed time:",mins,":",secs,sep=""))
              if (ce == 42) stop("The FTP server is not responding. Please try again later.") #stop after 21 minutes
            } else{
              ## write to file
              outfile = file ( paste(getwd(),'/',ModisName,sep=""), open="wb")
              writeBin(object = er, con = outfile ) 
              close(outfile)
              print(paste(ModisName,"successfully downloaded."))
              n.downloaded<-n.downloaded + 1
            }#ok: write to file
        }#while still trying
      }# for ModisName in Modislist
      print(paste("Image date ",dirs[i],": ",n.downloaded," files successfully downloaded.",sep=''))
      
      #create a date string for use in output filenames
      date_name <- sub(sub(pattern="\\.", replacement="_", dirs[i]), pattern="\\.", replacement="_", dirs[i])
      mosaicedFile<-paste(getwd(), '/Mosaic_',date_name,'.hdf',sep="")
      
      #Mosaic the files if requested
      if (length(Modislist) > 1 && mosaic){
        #Open a temporary file in the working directory and write the names of the files to be mosaiced in it as text.
        mosaic.input.list = file(paste(getwd(), "/temporary.mosaic.prm", sep=""), open="wt")
        write(paste(getwd(),"/",Modislist[1], sep=""), mosaic.input.list)
        for (j in 2:length(Modislist)) {
          write(paste(getwd(),"/",Modislist[j], sep=""),mosaic.input.list,append=T)
        }
        close(mosaic.input.list)

        #Mosaic the files.  A mosaiced file (hdf format) named "Mosaic_somedate.hdf" is put in the working directory.
        #The original tiles may be deleted from the working directory, depending on the value of "del"
        mosaicMODISjp(MRTLoc=MRTLoc,Modislist=Modislist,subset.bands=subset.bands,delete.hdf.originals=del,outfile=mosaicedFile)
      }#if(length(ModisList > 1 && mosaic))
      
      #Re-project the files if requested. Calls ProjectMODISjp().
      if (proj) {
        if(mosaic){
          #Get the file prefix to use in creating the output filename
          prefix <- strsplit(Modislist[1],'\\.')[[1]][1]
          outfile<-paste(prefix,'_',date_name,'.tif',sep='')
          #Attempt to reproject, using the mosaiced file as input
          e <- projectMODISjp('parameter.file',hdfName=mosaicedFile,output.name=outfile,MRTLoc=MRTLoc,UL=UL,LR=LR,projection=projection,parameters=parameters,utm.zone=utm.zone,pixel_size=pixel_size)
          if (e == 0 && del) {
            unlink(mosaicedFile) #delete the hdf file if the reprojection was successful and del=T
          }
        } else {
          #Go through the list of non-mosaiced files
          for (ModisName in Modislist){
            basename<-substr(ModisName, 1, tail(unlist(gregexpr("\\.", ModisName)), 1) - 1)
            outfile <- paste(basename,'.tif',sep = "")
            #Attempt to reproject, using the non-mosaiced original tile as input
            e <- projectMODISjp('parameter.file',hdfName=ModisName,output.name=outfile,MRTLoc=MRTLoc,subset.bands=subset.bands,UL=UL,LR=LR,projection=projection,parameters=parameters,utm.zone=utm.zone,pixel_size=pixel_size)
            if (e==0 && del) unlink(ModisName) #delete the hdf file if the reprojection was successful and del=T
          }#for modisName in modisList
        }#not mosaicing
        if (e != 0)  print ("reprojection Failed!")
      }#if proj 
    } else print(paste("There is no imagery on the server for the selected tiles in ",dirs[i], sep="")) #if length(ModisList > 0)
  }#for i in length(dirs)
}# function GetMODIS
#==================================

