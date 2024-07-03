#---------------------------------------
#---------Load packages-----------------
#---------------------------------------
library(sf)
library(tidyverse)


#---------------------------------------
#---------Read data---------------------
#---------------------------------------
gemeentes <- st_read("https://raw.githubusercontent.com/inbo/aspbo/main/data/output/UAT_processing/communes.geojson")
provincies <- st_read("https://raw.githubusercontent.com/inbo/aspbo/main/data/output/UAT_processing/provinces.geojson")
utm1<-sf::st_read("https://raw.githubusercontent.com/inbo/aspbo/main//data/output/UAT_processing/grid/utm1_bel_with_regions.gpkg", 
                  layer="utm1_bel_with_regions" )
utm10<-sf::st_read("https://raw.githubusercontent.com/inbo/aspbo/main/data/output/UAT_processing/grid/utm10_bel_with_regions.gpkg", 
                   layer="utm10_bel_with_regions" )


#---------------------------------------------------------
#-----------Make sure all data have the same crs----------
#---------------------------------------------------------
st_crs(utm10) == st_crs(utm1) 
st_crs(utm10) == st_crs(provincies)
st_crs(utm10) == st_crs(gemeentes)
gemeentes <- st_transform(gemeentes, crs = st_crs(utm10))
provincies <- st_transform(provincies, crs = st_crs(utm10))


#--------------------------------------------------------------------
#----------------link CELLCODE to province and commune---------------
#--------------------------------------------------------------------
utm10_gem <- st_intersection(utm10, gemeentes)
utm1_gem <- st_intersection(utm1, gemeentes)
utm10_prov <- st_intersection(utm10, provincies)
utm1_prov <- st_intersection(utm1, provincies)

# Calculate the area that each cell overlaps with the respective communes
#Note that the area of the utm10 pixels is 1e+08 [m^2] and that of utm1 is 1e+06 [m^2]
utm10_gem <- utm10_gem %>%
  mutate(intersection_area = st_area(.))
utm1_gem <- utm1_gem %>%
  mutate(intersection_area = st_area(.))
utm10_prov <- utm10_prov %>%
  mutate(intersection_area = st_area(.))
utm1_prov <- utm1_prov %>%
  mutate(intersection_area = st_area(.))

# Calculate the percentage of overlap
utm10_gem<- utm10_gem %>%
  mutate(overlap_percentage = round(as.numeric(intersection_area / 1e+08 * 100),2))
utm1_gem<- utm1_gem %>%
  mutate(overlap_percentage = round(as.numeric(intersection_area / 1e+06 * 100),2))
utm10_prov<- utm10_prov %>%
  mutate(overlap_percentage = round(as.numeric(intersection_area / 1e+08 * 100),2))
utm1_prov<- utm1_prov %>%
  mutate(overlap_percentage = round(as.numeric(intersection_area / 1e+06 * 100),2))

#Check if per cellcode, the percentages add up to 100% (only those on the edge could be lower)
utm10_gem%>%
  group_by(CELLCODE)%>%
  mutate(sumpercell= sum(overlap_percentage))%>%
  dplyr::filter(sumpercell<99.9)%>%
  plot(max.plot=1)#Looks ok

utm1_gem%>%
  group_by(CELLCODE)%>%
  mutate(sumpercell= sum(overlap_percentage))%>%
  dplyr::filter(sumpercell<99.3)%>%
  plot(max.plot=1) #Looks okish

utm10_prov%>%
  group_by(CELLCODE)%>%
  mutate(sumpercell= sum(overlap_percentage))%>%
  dplyr::filter(sumpercell<99.9)%>%
  plot(max.plot=1)#Looks ok

utm1_prov%>%
  group_by(CELLCODE)%>%
  mutate(sumpercell= sum(overlap_percentage))%>%
  dplyr::filter(sumpercell<99.5)%>%
  plot(max.plot=1) #Looks okish


#Keep only cells with the highest percentage coverage for each gemeente
utm1_gem<-utm1_gem%>%
  group_by(CELLCODE)%>%
  dplyr::filter(overlap_percentage==max(overlap_percentage))
utm10_gem<-utm10_gem%>%
  group_by(CELLCODE)%>%
  dplyr::filter(overlap_percentage==max(overlap_percentage))
utm1_prov<-utm1_prov%>%
  group_by(CELLCODE)%>%
  dplyr::filter(overlap_percentage==max(overlap_percentage))
utm10_prov<-utm10_prov%>%
  group_by(CELLCODE)%>%
  dplyr::filter(overlap_percentage==max(overlap_percentage))

#Maybe we should add a filter step to only assign communes when there is at least a certain percentage overlap

#utm1_gem<-dplyr::filter(utm1_gem, overlap_percentage>10)
#utm10_gem<-dplyr::filter(utm10_gem, overlap_percentage>10)
#utm1_prov<-dplyr::filter(utm1_prov, overlap_percentage>10)
#utm10_prov<-dplyr::filter(utm10_prov, overlap_percentage>10)

#Check which cells would be filtered out by this
plot(dplyr::filter(utm1_gem, overlap_percentage<10), max.plot=1)
plot(dplyr::filter(utm10_gem, overlap_percentage<10), max.plot=1)
plot(dplyr::filter(utm1_prov, overlap_percentage<10), max.plot=1)
plot(dplyr::filter(utm10_prov, overlap_percentage<10), max.plot=1)


#---------------------------------------------------------------------------------
#---------------- add the commune and province data to original file--------------
#---------------------------------------------------------------------------------
utm1_gemeentes<-dplyr::left_join(utm1, st_drop_geometry(utm1_gem), by = c("CELLCODE","isBrussels","isWallonia","isFlanders","EOFORIGIN","NOFORIGIN"))
utm10_gemeentes<-dplyr::left_join(utm10, st_drop_geometry(utm10_gem), by = c("CELLCODE","isBrussels","isWallonia","isFlanders","EOFORIGIN","NOFORIGIN"))
utm1_gemeentes_provincies<-dplyr::left_join(utm1_gemeentes, st_drop_geometry(utm1_prov), by = c("CELLCODE","isBrussels","isWallonia","isFlanders","EOFORIGIN","NOFORIGIN"))
utm10_gemeentes_provincies<-dplyr::left_join(utm10_gemeentes, st_drop_geometry(utm10_prov), by = c("CELLCODE","isBrussels","isWallonia","isFlanders","EOFORIGIN","NOFORIGIN"))

#Check for congruence between gewest assigned by province vs. commune data
not_same_gewest1<-dplyr::filter(utm1_gemeentes_provincies, GEWEST.x!=GEWEST.y) #8 utm1 pixels have a different gewest
not_same_gewest10<-dplyr::filter(utm10_gemeentes_provincies, GEWEST.x!=GEWEST.y)#2 utm10 pixels
mapview::mapview(list(gemeentes, provincies, not_same_gewest1), col.regions = c("green","yellow", "darkblue"))
mapview::mapview(list(gemeentes, provincies, not_same_gewest10), col.regions = c("green","yellow", "darkblue"))

#Select columns of interest (column gewest is kept from provincie left_join)
utm1_gemeentes_provincies<-utm1_gemeentes_provincies[,c(1:6,17,7:8,12:14)]
utm10_gemeentes_provincies<-utm10_gemeentes_provincies[,c(1:6,17,7:8,12:14)]

names(utm1_gemeentes_provincies)[8]<-"NISCODE_gemeente"
names(utm1_gemeentes_provincies)[9]<-"gemeente"
names(utm1_gemeentes_provincies)[10]<-"NISCODE_provincie"
names(utm1_gemeentes_provincies)[11]<-"provincie"
names(utm1_gemeentes_provincies)[12]<-"gewest"

names(utm10_gemeentes_provincies)[8]<-"NISCODE_gemeente"
names(utm10_gemeentes_provincies)[9]<-"gemeente"
names(utm10_gemeentes_provincies)[10]<-"NISCODE_provincie"
names(utm10_gemeentes_provincies)[11]<-"provincie"
names(utm10_gemeentes_provincies)[12]<-"gewest"

#check if extent makes sense
plot(utm10_gemeentes, max.plot=1)
plot(utm1_gemeentes, max.plot=1)


#----------------------------------------
#--- Save files again as geopackage------
#----------------------------------------
st_write(obj = utm1_gemeentes_provincies,
         dsn = "./data/output/UAT_processing/grid/utm1_bel_with_regions.gpkg",
         layer = "utm1_bel_with_regions",
         delete_dsn=TRUE)

st_write(obj = utm10_gemeentes_provincies,
         dsn = "./data/output/UAT_processing/grid/utm10_bel_with_regions.gpkg",
         layer = "utm10_bel_with_regions",
         delete_dsn=TRUE)
