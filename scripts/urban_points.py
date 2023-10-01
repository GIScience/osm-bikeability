"""This script creates 2d points within urban areas from the Global Human Settlement Layer (ghsl). 
They are used to create the hexagonial Discrete Global Grid with the resolution level of 20 (which corresponds to a cell-center distance of ~130m).
The points have a distance from each other of around 80 meters.
The points are stored in four csv files. 
Each file contains the urban areas of one major european region (eastern- , western- , northern- , southern europe).
The seperation into four files is necessary to enable automized processing of hexagons without abortion due to overloaded RAM.
"""

import geopandas as gpd
import shapely
import pandas as pd

def points_from_extent(extent, points):
    #get corner values (minimum and maximum values for x- and y-coordinate) from the extend 
    minX, minY, maxX, maxY = extent.bounds
    x, y = (minX, minY)

    # set square size of the cells
    square_size = 80
    #while vertical does not reach top row do following loop (y-100 to ensure top row includes whole extend):
    while y - square_size <= maxY: 
        #while horizontal does not reach most right cells, do following loop:
        while x <= maxX:
            #create cells Center
            point = shapely.geometry.Point(x + 0.5 * square_size, y + 0.5 * square_size)
            if point.within(extent) == True:
                points.append(point)
            #increase x coordinate to calculate the next cells
            x += square_size   
        x = minX
        y += square_size 

#get extend of urban areas
cities = gpd.GeoDataFrame.from_file('../data/ghsl/urban_europe.shp')

#reproject to metric projection to set metric distances between created points
cities = cities.to_crs("ESRI:54009")

#divide point creation in four major regions
regions = ["Northern_Europe", "Western_Europe", "Eastern_Europe", "Southern_Europe"]
counter = 0
for region in regions:
    cities_filtered = cities[cities["GRGN_L2"] == region]
    points = []
    all = len(cities_filtered)
    i = 0
    while i < len(cities_filtered):
        #create points for every urban area
        points_from_extent(cities_filtered.iloc[i]["geometry"], points)
        counter += 1
        print(region, counter, '/', all)
        i += 1
    print("Create GeoSeries")
    points = gpd.GeoSeries(data = points, crs = "ESRI:54009")
    print("Reproject to WGS84")
    points = points.to_crs("EPSG:4326")
    print("Dataframe")
    df = pd.DataFrame({'latitude': points.values.y, 'longitude': points.values.x})
    print("to csv")
    df.to_csv("../data/hexagons/" + region + "_points2.csv", index = False)
