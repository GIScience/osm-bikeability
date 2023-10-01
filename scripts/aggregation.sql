drop table {table_name}_aggregated;
create table {table_name}_aggregated as(
	select 
	b.city_id, 
	b."timestamp",	 
	AVG(b.bikeability_index) as bikeability_index, 
	b.city_name,  
	ue.geometry as geom,
	st_centroid(ue.geometry) as geom_centroid
	from {table_name} b join urban_eu ue on (b.city_id = ue.fid)
	group by b.city_id, b.city_name, b."timestamp", ue.geometry
)
