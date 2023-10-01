# Bikeability

Welcome to the Repository of how to calculate the so-called Bikeability-Index.

Bikeability means in this case the suitability of cycling.

## Description

The calculation is done for urban areas within europe for any given timestamp or timestamps. The values are calculated for hexagons of a cell-center-distance of ~130 meters. Additionally, an aggregated Bikeability-Index for each urban area is derived. 

The underlying data source is OpenStreetMap (OSM).

The results are stored in a user-given schema within the ohsome-hex database. 


A final visualisation is accessible at: https://hex.ohsome.org/#/index_bikeability.

For further information and a detailed description about the implementation, check out the documentation.md file.



## Execution

Clone this repository and run the script "process.py" in the folder "scripts"

```bash
python scripts/process.py
```

follow the initialisation instructions and input necessary information. 

Example:
```console
set credentials to ohsome-hex database:
username: mkraft
Password:
schema where to write to: mkraft
set timestamps in format 'yyyy-mm-dd', type 'q' to quit
Timestamp 1: 2019-05-02
Timestamp 2: 2016-03-04
Timestamp 3: 2013-04-17
Timestamp 4: q
```

## Requirements

- Access to the ohsome hex database

- Packages (named version is successfully tested but might not be necessary):
  - Python 3.8.6
  - SQL Alchemy 1.4.39
  - ohsome 0.1.0
  - pandas 1.5.3
  - geopandas 0.9.0
  - numpy 1.23.4

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.