create table if not exists {table_name}_unclassified(
	boundary integer,
	"timestamp" timestamp,
	length_of_infrastructure float,
	proportion_of_natural_area float,
	density_of_bike_parking_spots float,
	density_of_potential_destinations float,
	seperated_from_cars float,
	geometry geometry(polygon, 4326)
);

INSERT INTO {table_name}_unclassified
select 
ihecr.geohash_id as boundary,
v1."timestamp",
--value in meters
v1.value as length_of_infrastructure,
--Value in Percent
v2.value as proportion_of_natural_area,
--value as number
v3.value as density_of_bike_parking_spots,
--value as number
v4.value as density_of_potential_destinations,
--value as number
v5.value as seperated_from_cars,
ihecr.geom4326 as geometry

from 
grids.isea3h_europe_cities_res20 ihecr,
length_of_infrastructure v1,
proportion_of_natural_area v2,
density_of_bike_parking_spots v3,
density_of_potential_destinations v4,
seperated_from_cars v5

where 
ihecr.geohash_id = v1.boundary and 
v1.boundary = v2.boundary and 
v1."timestamp" = v2."timestamp" and 
v2.boundary = v3.boundary and 
v2."timestamp" = v3."timestamp" and 
v3.boundary = v4.boundary and 
v3."timestamp" = v4."timestamp" and 
v4.boundary = v5.boundary and 
v4."timestamp" = v5."timestamp"




