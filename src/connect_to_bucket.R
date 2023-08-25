connect_to_bucket <- function(bucket_type = "inbo-uat", 
                              bucket_name,
                              role = "inbo-developers-fis-role", 
                              boto3 = FALSE){
  # Libraries ####
  library(aws.s3)
  
  # Install boto3 ####
  if(boto3 == TRUE){
    system('pip install boto3')
  }
  
  # Refresh session token ####
  # Onderstaande code maakt een profiel aan met een sessiontoken die één uur 
  # geldig blijft. Deze heb je nodig om verbinding te maken met de s3 buckets.
  if(file.exists("../../../bin/aws-cli-mfa-login")){
    system(paste0('python ../../../bin/aws-cli-mfa-login -u ', 
                  Sys.getenv("USERNAME"), 
                  ' -a ', bucket_type, ' -r ', role))
  }else{
    stop("Installeer aws-cli-mfa-login van inbo/devops-tools in je windows home
         directory, zie wiki (WIP)")
  }
  
  # Set AWS profile name ####
  aws_profile <- paste0(bucket_type, "-", 
                        strsplit(Sys.getenv("USERNAME"), split = "-"))
  aws_profile <- gsub(pattern = "_", replacement = "-", x = aws_profile)
  
  Sys.setenv("AWS_PROFILE" = aws_profile)
  
  # Test connection ####
  filelist <- get_bucket_df(bucket = bucket_name, 
                            region = "eu-west-1")
  
  return(filelist)
}