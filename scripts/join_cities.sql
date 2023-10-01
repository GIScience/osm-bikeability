create table {table_name}_2 as(
	select 
	b.boundary,
	b."timestamp",
	b.proportion_of_natural_area,
	b.seperated_from_cars,
	b.density_of_potential_destinations,
	b.length_of_infrastructure,
	b.density_of_bike_parking_spots,
	b.bikeability_index,
	ue.fid as city_id,
	ue."UC_NM_MN" as city_name,
	b.geometry,
	ue.geometry as geom_city
	from {table_name} b 
	join urban_eu ue on(st_intersects(b.geometry, ue.geometry))
);

create index on {script_schema}.{table_name}_2 (boundary, "timestamp");
analyze {script_schema}.{table_name}_2;

with multiple_intersections as(
	select b.boundary, b."timestamp", count(*) from {table_name}_2 b
	group by b.boundary, b."timestamp" 
	having count(*) > 1
),

intersect_area as(
	select b.boundary, b."timestamp", b.city_id, b.city_name, st_area(st_intersection(b.geometry, b.geom_city)) as area 
	from {table_name}_2 b join multiple_intersections mlp on(mlp.boundary = b.boundary and mlp."timestamp" = b."timestamp")
	order by boundary, "timestamp", area desc
),

area_min as(
	select  ia.boundary, ia."timestamp", (array_agg(city_id))[2] as city_id from intersect_area ia
	group by ia.boundary, ia."timestamp"
)


delete from {table_name}_2 b
where exists(
	select * from area_min 
	where area_min.boundary = b.boundary and 
	area_min."timestamp" = b."timestamp" and
	area_min.city_id = b.city_id
);

drop table {table_name};

alter table {table_name}_2 
drop column geom_city;

alter table {table_name}_2
rename to {table_name};

