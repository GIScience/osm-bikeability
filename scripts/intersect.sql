drop index if exists natural_area_union_geometry_idx; 
create index natural_area_union_geometry_idx on natural_area_union using gist(st_subdivide);
analyze natural_area_union;

drop table if exists proportion_of_natural_area; 
create table proportion_of_natural_area as(
	--calculate area of Intersection
	with t1 as(
		select 
		ihecr.geohash_id as boundary,
		nau."timestamp",
		nau.st_subdivide,
		ihecr.geom4326 as geometry,
		coalesce (ST_Area(ST_Intersection(ihecr.geom4326 , nau.st_subdivide)), 0) as area_part,
		st_Area(ihecr.geom4326) as area_cell
		from 
		grids.isea3h_europe_cities_res20 ihecr, 
		natural_area_union nau 
		where ST_Intersects(ihecr.geom4326, nau.st_subdivide)
	),
		
	--calculate proportion of Intersection
	t2 as(
		select
		t1.boundary, 
		t1."timestamp", 
		round((sum(t1.area_part)/area_cell)::numeric, 3) * 100 as value
		from t1
		group by t1.boundary, t1."timestamp", t1.area_cell
	)
	
	--add boundaries with timestamps without calculated values and set them to zero	
	select 
	loi.boundary, 
	loi."timestamp", 
	coalesce(t2.value, 0) as value
	from length_of_infrastructure loi left join t2 on (
		loi.boundary = t2.boundary and loi."timestamp" = t2."timestamp"
	)
)


