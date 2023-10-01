import geopandas as gpd
from sqlalchemy import create_engine


username = input("username: ")
password = input("password: ")
table_name = input("name of the hexagon table: ")
schema = input("schema where to write to: ")


engine = create_engine(f"postgresql://{username}:{password}@heigitsv07.heigit.org:5434/ohsome-hex")

regions = ["Northern_Europe", "Southern_Europe", "Western_Europe", "Eastern_Europe"]
for region in regions:
    print(f"region {region}...")
    gdf = gpd.read_file(f'../data/hexagons/{region}/{region}.shp')
    gdf.to_postgis("hexagon_temp", engine, schema = schema, if_exists = "append")

#create hexagon table with ordered geohash id (ensures that neighbouring hexagon id's are spatially close to each other)
print("create ordered geohash id")
engine.execute(f"""
    CREATE TABLE {schema}.{table_name} AS 
    SELECT 
    ROW_NUMBER() OVER (ORDER BY geometry)::int8 AS geohash_id,
    geometry::geometry(POLYGON,4326) AS geom 
    FROM {schema}.hexagon_temp;""")

#drop temporary hexagon table
engine.execute("DROP TABLE hexagon_temp;")

#add buffer boundaries 
print("add buffer boundaries")
engine.execute(f"""alter table {schema}.{table_name}
add column buffer100 geometry(polygon, 4326);

alter table {schema}.{table_name}
add column buffer250 geometry(polygon, 4326);

update {schema}.{table_name}
set buffer100 = st_buffer(st_centroid(geom)::geography, 100, 10)::geometry;

update {schema}.{table_name}
set buffer250 = st_buffer(st_centroid(geom)::geography, 250, 20)::geometry;""")