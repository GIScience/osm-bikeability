drop table if exists bikeability_orientation; 
create table bikeability_orientation as(
	with orientation_hex as(
		select bu.* from bikeability_unclassified bu join bikeability_orientation_boundaries ob 
		on st_intersects(ob.geometry, bu.geometry)
	),
	statistics_union as(
		select 
		'Average' as "statistics",
		"timestamp",
		ROUND(avg(length_of_infrastructure)::numeric, 0) as length_of_infrastructure ,
		ROUND(avg(proportion_of_natural_area)::numeric, 1) as proportion_of_natural_area,
		ROUND(avg(density_of_bike_parking_spots)::numeric, 2) as density_of_bike_parking_spots,
		ROUND(avg(density_of_potential_destinations)::numeric, 1) as density_of_potential_destinations,
		ROUND(avg(seperated_from_cars)::numeric, 2) as seperated_from_cars
		from orientation_hex
		group by "timestamp"
		
		union
		
		select 
		'Median' as "statistics",
		"timestamp",
		ROUND(percentile_cont(0.5) within group (order by length_of_infrastructure)::numeric, 0) as length_of_infrastructure,
		ROUND(percentile_cont(0.5) within group (order by proportion_of_natural_area)::numeric, 1) as proportion_of_natural_area ,
		ROUND(percentile_cont(0.5) within group (order by density_of_bike_parking_spots)::numeric, 2) as density_of_bike_parking_spots ,
		ROUND(percentile_cont(0.5) within group (order by density_of_potential_destinations)::numeric, 1) as density_of_potential_destinations,
		ROUND(percentile_cont(0.5) within group (order by seperated_from_cars)::numeric, 2) as seperated_from_cars
		from orientation_hex
		group by "timestamp"
		
		union
		
		select 
		'67_Percentile' as "statistics",
		"timestamp",
		ROUND(percentile_cont(0.67) within group (order by length_of_infrastructure)::numeric, 0) as length_of_infrastructure,
		ROUND(percentile_cont(0.67) within group (order by proportion_of_natural_area)::numeric, 1) as proportion_of_natural_area ,
		ROUND(percentile_cont(0.67) within group (order by density_of_bike_parking_spots)::numeric, 2) as density_of_bike_parking_spots ,
		ROUND(percentile_cont(0.67) within group (order by density_of_potential_destinations)::numeric, 1) as density_of_potential_destinations,
		ROUND(percentile_cont(0.67) within group (order by seperated_from_cars)::numeric, 2) as seperated_from_cars
		from orientation_hex 
		group by "timestamp"
		
		union
		
		select 
		'Standard_Deviation' as "statistics",
		"timestamp",
		ROUND(stddev(length_of_infrastructure)::numeric, 0) as length_of_infrastructure,
		ROUND(stddev(proportion_of_natural_area)::numeric, 1) as proportion_of_natural_area,
		ROUND(stddev(density_of_bike_parking_spots)::numeric, 2) as density_of_bike_parking_spots ,
		ROUND(stddev(density_of_potential_destinations)::numeric, 1) as density_of_potential_destinations,
		ROUND(stddev(seperated_from_cars)::numeric, 2) as seperated_from_cars 
		from orientation_hex 
		group by "timestamp"
		
		union
		
		select 
		'Coefficient_of_Variation' as "statistics",
		"timestamp",
		CASE WHEN avg(length_of_infrastructure) = 0 then 0 else ROUND((stddev(length_of_infrastructure)/avg(length_of_infrastructure))::numeric, 2) end as length_of_infrastructure,
		CASE WHEN avg(proportion_of_natural_area) = 0 then 0 else ROUND((stddev(proportion_of_natural_area)/avg(proportion_of_natural_area))::numeric, 2) end as proportion_of_natural_area,
		CASE WHEN avg(density_of_bike_parking_spots) = 0 then 0 else ROUND((stddev(density_of_bike_parking_spots)/avg(density_of_bike_parking_spots))::numeric, 2) end as density_of_bike_parking_spots,
		CASE WHEN avg(density_of_potential_destinations) = 0 then 0 else ROUND((stddev(density_of_potential_destinations)/avg(density_of_potential_destinations))::numeric, 2) end as density_of_potential_destinations,
		CASE WHEN avg(seperated_from_cars) = 0 then 0 else ROUND((stddev(seperated_from_cars)/avg(seperated_from_cars))::numeric, 2) end as seperated_from_cars 
		from orientation_hex
		group by "timestamp"
	)
	select 
	"statistics",
	round(avg(length_of_infrastructure), 1) as length_of_infrastructure, 
	round(avg(proportion_of_natural_area), 1) as proportion_of_natural_area,
	round(avg(density_of_potential_destinations), 1) as density_of_potential_destinations
	from statistics_union 
	where "timestamp" = '2023-01-01 01:00:00.000 +0100'
	group by
	"statistics", "timestamp"
)