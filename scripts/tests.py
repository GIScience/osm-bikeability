from ohsome import OhsomeClient
import pandas as pd
import geopandas as gpd
from sqlalchemy import create_engine

client = OhsomeClient()

engine = create_engine("postgresql://mkraft:mkraft#2022@heigitsv07.heigit.org:5434/ohsome-hex")

table_name = "bikeabilityTest"
schema = "mkraft"

#join city information
with open("join_cities.sql") as file:
    engine.execute(file.read().format(table_name = table_name, script_schema = schema))

#group bikeability values by city and timestamp and store in new table
with open("aggregation.sql") as file:
    engine.execute(file.read().format(table_name = table_name, script_schema = schema))


