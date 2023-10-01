alter table length_of_infrastructure 
alter column boundary type integer using boundary::integer;

alter table density_of_bike_parking_spots 
alter column boundary type integer using boundary::integer;

alter table density_of_potential_destinations  
alter column boundary type integer using boundary::integer;

alter table seperated_from_cars  
alter column boundary type integer using boundary::integer;

alter table natural_geometries  
alter column "@snapshotTimestamp" type timestamptz using "@snapshotTimestamp" at time zone 'UTC';

ALTER TABLE natural_geometries
ALTER COLUMN geometry TYPE geometry(geometry, 3035) USING ST_Transform(geometry, 3035);
