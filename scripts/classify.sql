create table if not exists {table_name}(
boundary integer,
"timestamp" timestamptz,
proportion_of_natural_area integer,
seperated_from_cars integer,
density_of_potential_destinations integer,
length_of_infrastructure integer,
density_of_bike_parking_spots integer,
bikeability_index float,
geometry geometry(polygon, 4326)
);

with intervallMax as(
	select 
	length_of_infrastructure,
	proportion_of_natural_area,
	density_of_potential_destinations
	from bikeability_orientation
	where "statistics" = '67_Percentile'
),
--classify indicator values
classification as(
	SELECT 
	boundary,
	"timestamp",
	CASE 
		WHEN proportion_of_natural_area >= (select proportion_of_natural_area * 0.9 from intervallMax) THEN 10
		WHEN proportion_of_natural_area >= (select proportion_of_natural_area * 0.8 from intervallMax) THEN 9
		WHEN proportion_of_natural_area >= (select proportion_of_natural_area * 0.7 from intervallMax) THEN 8
		WHEN proportion_of_natural_area >= (select proportion_of_natural_area * 0.6 from intervallMax) THEN 7
		WHEN proportion_of_natural_area >= (select proportion_of_natural_area * 0.5 from intervallMax) THEN 6
		WHEN proportion_of_natural_area >= (select proportion_of_natural_area * 0.4 from intervallMax) THEN 5
		WHEN proportion_of_natural_area >= (select proportion_of_natural_area * 0.3 from intervallMax) THEN 4
		WHEN proportion_of_natural_area >= (select proportion_of_natural_area * 0.2 from intervallMax) THEN 3
		WHEN proportion_of_natural_area >= (select proportion_of_natural_area * 0.1 from intervallMax) THEN 2
		ELSE 1
	END AS proportion_of_natural_area, 
	CASE 
		WHEN density_of_potential_destinations >= (select density_of_potential_destinations * 0.9 from intervallMax) THEN 10
		WHEN density_of_potential_destinations >= (select density_of_potential_destinations * 0.8 from intervallMax) THEN 9
		WHEN density_of_potential_destinations >= (select density_of_potential_destinations * 0.7 from intervallMax) THEN 8
		WHEN density_of_potential_destinations >= (select density_of_potential_destinations * 0.6 from intervallMax) THEN 7
		WHEN density_of_potential_destinations >= (select density_of_potential_destinations * 0.5 from intervallMax) THEN 6
		WHEN density_of_potential_destinations >= (select density_of_potential_destinations * 0.4 from intervallMax) THEN 5
		WHEN density_of_potential_destinations >= (select density_of_potential_destinations * 0.3 from intervallMax) THEN 4
		WHEN density_of_potential_destinations >= (select density_of_potential_destinations * 0.2 from intervallMax) THEN 3
		WHEN density_of_potential_destinations >= (select density_of_potential_destinations * 0.1 from intervallMax) THEN 2
		ELSE 1
	END AS density_of_potential_destinations,
	CASE 
		WHEN length_of_infrastructure >= (select length_of_infrastructure * 0.9 from intervallMax) THEN 10
		WHEN length_of_infrastructure >= (select length_of_infrastructure * 0.8 from intervallMax) THEN 9
		WHEN length_of_infrastructure >= (select length_of_infrastructure * 0.7 from intervallMax) THEN 8
		WHEN length_of_infrastructure >= (select length_of_infrastructure * 0.6 from intervallMax) THEN 7
		WHEN length_of_infrastructure >= (select length_of_infrastructure * 0.5 from intervallMax) THEN 6
		WHEN length_of_infrastructure >= (select length_of_infrastructure * 0.4 from intervallMax) THEN 5
		WHEN length_of_infrastructure >= (select length_of_infrastructure * 0.3 from intervallMax) THEN 4
		WHEN length_of_infrastructure >= (select length_of_infrastructure * 0.2 from intervallMax) THEN 3
		WHEN length_of_infrastructure >= (select length_of_infrastructure * 0.1 from intervallMax) THEN 2
		ELSE 1
	END AS length_of_infrastructure,
	case  
		when density_of_bike_parking_spots >= 1 then 10
		else 1
	end as density_of_bike_parking_spots,
	case  
		when seperated_from_cars >= 1 then 10
		else 1
	end as seperated_from_cars,
	geometry
	FROM {table_name}_unclassified
)
INSERT INTO {table_name}
select 
boundary,
"timestamp",
proportion_of_natural_area,
seperated_from_cars,
density_of_potential_destinations,
length_of_infrastructure,
density_of_bike_parking_spots,
cast(
	proportion_of_natural_area + 
	seperated_from_cars + 
	density_of_potential_destinations + 
	length_of_infrastructure +
	density_of_bike_parking_spots as float) / 5 as bikeability_index,
geometry
from classification