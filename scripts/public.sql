create table public.index_bikeability_aggregated as (
select city_id as id,
"timestamp",
bikeability_index,
city_name,
country,
st_transform(geom, 3857) as geom,
st_transform(geom_centroid, 3857) as centroid
from mkraft.bikeability_aggregated
);

CREATE VIEW public.index_bikeability_polygon AS
SELECT 
id,
"timestamp",
bikeability_index,
city_name,
country, 
geom 
FROM public.index_bikeability_aggregated;

CREATE VIEW public.index_bikeability_point AS
SELECT 
id,
"timestamp",
bikeability_index,
city_name,
country, 
centroid 
FROM public.index_bikeability_aggregated;