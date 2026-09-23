#' render single html
#' 
#' @param input_file Path to the .Rmd file to render
#' @param output_path Path to the folder where the .HTML files will be saved
#' 
#' @return NULL
#' 
render_single_html <- function(input_file,output_path) {
  
  for(translation in c("nl","fr","en")){
    
    # Read the YAML header of the .Rmd file
    yaml_header<-rmarkdown::yaml_front_matter(input_file)
    
    # Extract the title from the YAML header
    title <- yaml_header$title
    
    # Define output file name based on the title and the language in which the .Rmd will be rendered
    output_file <- paste0(output_path,title,"_",translation, ".html")
    
    #Render
    rmarkdown::render(input =  input_file, output_file = output_file, params = list(language = translation), envir = new.env())
  }
}

