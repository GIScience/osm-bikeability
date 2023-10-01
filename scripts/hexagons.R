library(dggridR)
library(sf)

regions <- c("Northern_Europe", "Southern_Europe", "Western_Europe", "Eastern_Europe")

for (region in regions) {
  print(paste("Processing region:", region))
  file_path <- paste0("C:/Heigit/bikeability/data/hexagons/", region, "_points.csv")
  
  #read points
  df <- read.csv(file_path)
  
  #construct global hexagons id's
  dg <- dgconstruct(res = 20)
  
  #refer hexagon id's to points
  df$cell <- dgGEO_to_SEQNUM(dg, df$longitude, df$latitude)$seqnum
  
  #transform hexagon id's to geometries
  grid <- dgcellstogrid(dg, df$cell)
  
  #write hexagons to shapefile
  output_path <- paste0("C:/Heigit/bikeability/data/hexagons/", region)
  st_write(grid, dsn = output_path, driver = "Esri SHAPEFILE", append = FALSE)
}