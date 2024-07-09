#------------------------
#--1.Load Packages-------
#------------------------

packages <- c("rmarkdown", "fs")

for(i in packages) {
  print(i)
  if( ! i %in% rownames(installed.packages()) ) { install.packages( i ) }
  library(i, character.only = TRUE)
}

#------------------------------------------------------------------------------
#--2.Create funtion to render all .Rmd files in a certain folder to HTML-------
#------------------------------------------------------------------------------
render_rmd_files <- function(input_path,output_path) {
  
  # List all .Rmd files in the folder
  rmd_files <- dir_ls(input_path, glob = "*.Rmd")
  

  for (rmd_file in rmd_files) {
    for(translation in c("nl","fr","en")){
      
      # Read the YAML header of the .Rmd file
      yaml_header<-yaml_front_matter(rmd_file)
      
      # Extract the title from the YAML header
      title <- yaml_header$title
      
      # Define output file name based on the title and the language in which the .Rmd will be rendered
      output_file <- paste0(output_path,title,"_",translation, ".html")
      
      #Render
      render(input =  rmd_file, output_file = output_file, params = list(language = translation), envir = new.env())
    }
  }
  
}


#------------------------------------------------------------------------------
#--3.Run function-------
#------------------------------------------------------------------------------

# Specify the folder containing the .Rmd files
input_path <- "./HTML_pages/Rmd_files/"

# Specify the output folder for the .HTML files, note that this is written from the point of view of the .Rmd file location
output_path <- "../HTML/" 

#Run
render_rmd_files(input_path=input_path, output_path=output_path)
