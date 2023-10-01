alter table {schema}.{table_name}
add column buffer100 geometry(polygon, 4326);

alter table {schema}.{table_name}
add column buffer250 geometry(polygon, 4326);

update {schema}.{table_name}
set buffer100 = st_buffer(st_centroid(geom)::geography, 100, 10)::geometry;

update {schema}.{table_name}
set buffer250 = st_buffer(st_centroid(geom)::geography, 250, 20)::geometry;
