drop table if exists natural_area_union;
update natural_geometries 
set geometry = ST_MakeValid(geometry)
where ST_IsValid(geometry) = false;
DO $$ 
BEGIN
IF EXISTS (
      SELECT 1
      FROM information_schema.columns
      WHERE table_name = 'natural_geometries'
        AND column_name = 'waterway'
    ) THEN
      EXECUTE 
	  '	ALTER TABLE natural_geometries
		ALTER COLUMN geometry TYPE geometry(geometry, 3035) USING ST_Transform(geometry, 3035);
		
	  create table natural_area_union as(
	with trees as (
		select "@snapshotTimestamp", st_union(st_buffer(geometry, 5)) as geometry from natural_geometries
		where "natural" = ''tree''
		group by "@snapshotTimestamp"
	),
	stream as (
		select "@snapshotTimestamp", st_union(st_buffer(geometry, 1)) as geometry from natural_geometries 
		where waterway = ''stream''
		group by "@snapshotTimestamp"
	),
	drain as (
		select "@snapshotTimestamp", st_union(st_buffer(geometry, 0.3)) as geometry from natural_geometries
		where waterway = ''drain''
		group by "@snapshotTimestamp"
	),
	canal as (
		select "@snapshotTimestamp", st_union(st_buffer(geometry, 10)) as geometry from natural_geometries 
		where waterway = ''canal''
		group by "@snapshotTimestamp"
	),
	polygons as(
		select "@snapshotTimestamp", st_union(geometry) as geometry from natural_geometries
		where st_geometrytype(geometry) in (''ST_Polygon'', ''ST_MultiPolygon'', ''ST_GeometryCollection'')
		group by "@snapshotTimestamp"
	)

	select "@snapshotTimestamp" as "timestamp", ST_Subdivide(st_union(geometry)) from (
		select "@snapshotTimestamp", geometry from trees
		union 
		select "@snapshotTimestamp", geometry from stream
		union 
		select "@snapshotTimestamp", geometry from drain
		union 
		select "@snapshotTimestamp", geometry from canal
		union 
		select "@snapshotTimestamp", geometry from polygons
	) as t1
	group by t1."@snapshotTimestamp"
	);
	ALTER TABLE natural_area_union
	ALTER COLUMN st_subdivide TYPE geometry(geometry, 4326) USING ST_Transform(st_subdivide, 4326);';
	else
		execute '
	ALTER TABLE natural_geometries
	ALTER COLUMN geometry TYPE geometry(geometry, 3035) USING ST_Transform(geometry, 3035);
	create table natural_area_union as(
	with trees as(
	 	select "@snapshotTimestamp", st_union(st_buffer(geometry, 5)) as geometry from natural_geometries
		where "natural" = ''tree''
		group by "@snapshotTimestamp"
	),
	polygons as(
	select "@snapshotTimestamp", st_union(geometry) as geometry from natural_geometries
		where st_geometrytype(geometry) in (''ST_Polygon'', ''ST_MultiPolygon'', ''ST_GeometryCollection'')
		group by "@snapshotTimestamp"
	)
	select "@snapshotTimestamp" as "timestamp", ST_Subdivide(st_union(geometry)) from (
		select "@snapshotTimestamp", geometry from trees
		union  
		select "@snapshotTimestamp", geometry from polygons
	) as t1
	group by t1."@snapshotTimestamp"
	);
	ALTER TABLE natural_area_union
	ALTER COLUMN st_subdivide TYPE geometry(geometry, 4326) USING ST_Transform(st_subdivide, 4326);
	';
  END IF; 
END $$;

update natural_area_union 
set st_subdivide = ST_MakeValid(st_subdivide)
where ST_IsValid(st_subdivide) = false;


