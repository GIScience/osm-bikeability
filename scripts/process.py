"""
This script creates a table with classified bikeability values for urban hexagons from europe.
If a same-named table with bikeability data already exists, the calculated data will be appended.

Prerequisites: Access to ohsome-hex database
"""

from sqlalchemy import create_engine
from ohsome import OhsomeClient
import pandas as pd
import geopandas as gpd
import numpy as np
import datetime
import time
import getpass

def to_dataframe(request, geohash_id):
    count_boundaries = len(request.data["groupByResult"])
    count_timestamps = len(request.data["groupByResult"][0]["result"])
    rows = count_boundaries * count_timestamps
    dates = np.empty(rows, dtype = datetime.datetime)
    values = np.empty(rows)
    boundaries = np.empty(rows, dtype = int)
    i = 0
    for j in range(count_boundaries):
        for k in range(count_timestamps):
            dates[i] = request.data["groupByResult"][j]["result"][k]["timestamp"]
            boundaries[i] = int(request.data["groupByResult"][j]["groupByObject"]) + geohash_id 
            values[i] = request.data["groupByResult"][j]["result"][k]["value"]
            i += 1
    dates = pd.to_datetime(dates)
    df = pd.DataFrame({'timestamp': dates, 'boundary' : boundaries, 'value': values})
    df.set_index(["boundary", "timestamp"], inplace = True)
    return df

def osm_to_postgis(hexagons, geohash_id):
    print(indicator)
    with open(f"../filter/{indicator}.txt") as file:
        filter = file.read()
        if indicator == "proportion_of_natural_area":
            response = client.elements.geometry.post(bpolys = hexagons, filter = filter, properties = "tags", time = timestamps)
            df_nature = response.as_dataframe().reset_index()
            #Move geometry column to Last
            geom_column = df_nature.pop("geometry")
            df_nature.insert(len(df_nature.columns), "geometry", geom_column)
            if '' in df_nature.columns:
                df_nature.drop(columns = '', inplace = True)
            df_nature.to_postgis("natural_geometries", engine, schema = schema, if_exists = "replace")
            return 0
        elif indicator == "length_of_infrastructure":
            request = client.elements.length.groupByBoundary.post(bpolys = hexagons, filter=filter, time = timestamps)
        else:
            request = client.elements.count.groupByBoundary.post(bpolys = hexagons, filter=filter, time = timestamps)
        df = to_dataframe(request, geohash_id)
        df.to_sql(indicator, engine, schema = schema, if_exists = "replace", index = True)

def set_timestamps():
    date_format = '%Y-%m-%d'
    timestamp_list = []
    print("set timestamps in format 'yyyy-mm-dd', type 'q' to quit")
    while True:
        timestamp = input(f"Timestamp {len(timestamp_list) + 1}: ")
        if timestamp == 'q':
            break
        try:
            datetime.datetime.strptime(timestamp, date_format)
            timestamp_list.append(timestamp)
        except ValueError:
            print("Incorrect timestamp, check correct format (YYYY-MM-DD) and date existence (e.g. '2010-13-05' is not an existing date)")

    #return timestamp list without duplicates
    return list(dict.fromkeys(timestamp_list))

def set_connection():
    print("set credentials to ohsome-hex database:")
    username = input("username: ")
    password = getpass.getpass('Password:')
    schema = input("schema where to write to: ")
    try:
        engine = create_engine(f"postgresql://{username}:{password}@heigitsv07.heigit.org:5434/ohsome-hex")
        engine.execute("SELECT * FROM information_schema.tables")
    except Exception:
        exit("Error: No valid login credentials or no valid connection to the database")
    try:
        data = {'test_column1': ['value1', 'value2']}
        df = pd.DataFrame(data)
        df.to_sql("test_table", engine, schema = schema, if_exists = "replace", index = True)
        engine.execute("DROP TABLE test_table")
    except Exception:
        exit("Error: Schema not existing or no writing rights")

    return [create_engine(f"postgresql://{username}:{password}@heigitsv07.heigit.org:5434/ohsome-hex"), schema]

def handle_timestamps(geohash_id):
    #get unhandy timestamps
    query = f"""select b."timestamp" from mkraft.{table_name} b 
            where b.boundary between {geohash_id} and {geohash_id + block_count - 1}
            group by b."timestamp" 
            having count(*) != {block_count}"""
    timestamps_drop = engine.execute(query)
    timestamps_drop = [str(i[0])[:10] for i in timestamps_drop.fetchall()]
    timestamps_drop = set(timestamps_drop).intersection(timestamp_list)

    #get valid existing timestamps and detect further unhandy timestamps
    query = f"""select b."timestamp" from mkraft.{table_name} b 
            where b.boundary between {geohash_id} and {geohash_id + block_count - 1}
            group by b."timestamp" 
            having count(*) = {block_count}"""
    timestamps_temp = engine.execute(query)
    timestamps_temp = [str(i[0]) for i in timestamps_temp.fetchall()]
    timestamps_current = []
    for timestamp in timestamps_temp:
        query = f"""select count(distinct b.boundary) from mkraft.{table_name} b
                where b.boundary between {geohash_id} and {geohash_id + block_count - 1}
                and b."timestamp" = '{timestamp}'"""
        if engine.execute(query).fetchone()[0] != block_count:
            timestamps_drop.add(timestamp[:10])        
        else:
            timestamps_current.append(timestamp[:10])

    #delete unhandy timestamps
    if len(timestamps_drop) > 0:
        timestamps_drop_string = ''
        for timestamp in timestamps_drop:
            timestamps_drop_string += f",'{timestamp}'"
        query = f"""delete from mkraft.bikeability_unclassified2 
                    where "timestamp" in ({timestamps_drop_string[1:]})
                    and boundary between {geohash_id} and {geohash_id + block_count - 1}"""
        engine.execute(query)
    
    #get final timestamps and ignore valid existing timestamps
    timestamps_filtered = list(timestamp_list)
    for timestamp in timestamp_list:
        if timestamp in timestamps_current:
            timestamps_filtered.remove(timestamp)

    return ','.join(timestamps_filtered)


#set connection to ohsome api
client = OhsomeClient()

#set connection to ohsome-hex database
engine_schema = set_connection()
engine = engine_schema[0]
schema = engine_schema[1]

#set time period
timestamp_list = set_timestamps()
timestamps = ','.join(timestamp_list)

#set start id
geohash_id = 1

#set number of requested hexagons per loop
block_count = 300

#set table name
table_name = "bikeability"

#set boundaries for indicators (according to study from Heinemann 2022)
indicator_boundaries = {
    "density_of_bike_parking_spots": "buffer100",
    "density_of_potential_destinations": "buffer250",
    "length_of_infrastructure": "buffer250",
    "seperated_from_cars": "geom4326",
    "proportion_of_natural_area": "geom4326"
}

#upload orientation table for classification
df = pd.read_csv("../data/orientation_table.csv")
df.to_sql("bikeability_orientation", engine, schema = schema, if_exists='replace', index=False)

#upload urban layer for aggregation
gdf = gpd.read_file("../data/ghsl/urban_europe.shp").to_crs("EPSG:4326")
gdf[["fid", "CTR_MN_NM", "GRGN_L2", "UC_NM_MN", "geometry"]].to_postgis("urban_eu", engine, schema = schema, if_exists = "replace")

#get number of all hexagons within european cities
total_hexagons = engine.execute("SELECT count(*) from grids.isea3h_europe_cities_res20").fetchone()[0]

#check if table already exists
table_exists = engine.execute(f"SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = '{table_name}')").fetchone()[0]

#check whether classified values can be appended or not
if table_exists:
    col_number = engine.execute(f"SELECT COUNT(*) AS NUMBEROFCOLUMNS FROM information_schema.columns WHERE table_name = '{table_name}';").fetchone()[0]
    if col_number > 9:
        exit(f"Abortion: drop city attributes of the table '{schema}.{table_name}' first so that the classified values can be appended")

#fetch urban hexagons, download osm data, get bikeability indicator values, calculate bikeability index for each urban hexagon
while geohash_id <= total_hexagons:
    print(geohash_id - 1)

    start = time.time()

    #ignore timestamps that are already calculated and remove possible inconsistencies
    if table_exists:
        timestamps = handle_timestamps(geohash_id)

    #fetch urban hexagons, download indicator values for remaining timestamps, upload to postgis
    if timestamps != '':
        query = f"SELECT * FROM grids.isea3h_europe_cities_res20 WHERE geohash_id BETWEEN {geohash_id} AND {geohash_id + block_count - 1}"
        for indicator, boundary in indicator_boundaries.items():
            hexagons = gpd.read_postgis(query, engine, geom_col = boundary)
            osm_to_postgis(hexagons, geohash_id)

        #alter datatypes, prepare postgis tables for join, join indicator tables, classifiy indicator values, drop temporary tables
        statements = ["alter", "union", "intersect", "join", "classify", "drop"]
        for statement in statements:
            with open(statement + '.sql') as file:
                engine.execute(file.read().format(table_name = table_name))

        end = time.time()
        print(f"{round(block_count / (end - start), 1)} Hexagons per Second ({round((geohash_id + block_count) / total_hexagons, 3)}%)")
            
    geohash_id += block_count

#join city information
with open("join_cities.sql") as file:
    engine.execute(file.read().format(table_name = table_name, script_schema = schema))

#group bikeability values by city and timestamp and store in new table
with open("aggregation.sql") as file:
    engine.execute(file.read().format(table_name = table_name, script_schema = schema))

#add index for faster queries and manipulation
engine.execute(f'CREATE INDEX {table_name}_boundary_timestamp_idx ON {schema}.{table_name} USING btree (boundary, "timestamp"')

#drop urban layer
engine.execute("DROP TABLE urban_eu;")

#drop orientation layer
engine.execute("DROP TABLE bikeability_orientation")

