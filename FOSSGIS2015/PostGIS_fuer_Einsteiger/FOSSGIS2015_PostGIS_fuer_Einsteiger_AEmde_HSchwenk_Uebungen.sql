-- SQL Beispiele zum Workshop PostGIS für Einsteiger
-- http://www.fossgis.de/konferenz/2015/programm/events/794.de.html

--Daten für den Workshop
-- OSGEO-Live unter: /home/user/data/natural_earth2/


-- OSM
-- http://download.geofabrik.de/europe/germany/nordrhein-westfalen/muenster-regbez-latest.shp.zip



-- Kommentare erfolgen über --

------------------------------------------------------------------
-- Übung 1: pgAdmin III
------------------------------------------------------------------

-- 1.1 Anlegen einer Datenbank mit PostGIS Erweiterung

CREATE DATABASE fossgis;

--Wechseln zur Datenbank fossgis

CREATE EXTENSION postgis;

-- 1.2 Tabelle anlegen
-- poi - eine einfache Tabelle
CREATE TABLE poi (
   gid serial,
   name varchar,
   geom geometry( point , 4326 ),
  CONSTRAINT pk_poi_gid PRIMARY KEY (gid)
);


-- 1.3 Füllen der Tabelle poi mit Daten
INSERT INTO poi (name , geom) VALUES 
('Schloß Münster', 
ST_SetSRID(ST_MakePoint(7.61334,51.963586), 4326)
);

INSERT INTO poi (name , geom) VALUES 
('Aasee Münster', 
ST_GeometryFromText('POINT(7.62517 51.95616)', 4326)
);


-- 1.4 Anzeige der Daten (SQL Editor oder Tabellensymbol)
SELECT *, ST_AsText(geom) from poi;

-- Anzeige der Sicht geometry_column
SELECT * from geometry_column;


-- poi Ausgabe der Geometrie als WKT, EWKT, Lon und Lat
SELECT geom, ST_AsText(geom), ST_AsEKWT(geom), ST_X(geom), ST_Y(geom) from poi;



------------------------------------------------------------------
-- Übung 2: Natural Earth2
------------------------------------------------------------------
--2.1 QGIS SQL-Fenster oder pgAdmin SQL-Editor verwenden

-- QGIS Filter auf ne_10m_admin_1_states_provinces_shp
admin = 'Germany'

-- Import der Daten (nur admin='Germany') unter dem Namen laender
-- ESPG 4326

-- SQL Editor
-- Nur NRW ausgeben
SELECT * FROM laender WHERE admin = 'Germany' AND name = 'Nordrhein-Westfalen'

-- Berechung der Fläche der Länder
SELECT ST_Area(geom), * from laender;

SELECT ST_Area(ST_transform(geom,25832)) as flaeche, * from laender;

--- das größte Bundesland?
SELECT ST_Area(ST_transform(geom,25832)) as flaeche, * from laender ORDER BY flaeche DESC LIMIT 1;

-- In welchem Bundesland liegen die pois?
SELECT poi.*, l.* from poi, laender l
WHERE st_distance(poi.geom, l.geom) = 0; 


-- ST_UNION - Vereinigen der Bundeslaender
Create view brd as 
Select 1, st_union(geom) as geom from laender;



-- Import der Natural Earth2 river in die Tabelle fluesse (mit gid, Geometrieindex und Angeb der Projektion EPSG 4326)

-- ST_Buffer - Puffern von Daten
Create view fluesse_puffer as
Select gid,name, 
st_buffer(geom,0.0001)::geometry(polygon,4326) as geom_buffer 
from fluesse WHERE name = 'Rhine';


------------------------------------------------------------------
-- Übung 3: 
------------------------------------------------------------------
--3.1 QGIS SQL-Fenster oder pgAdmin SQL-Editor verwenden

CREATE OR REPLACE VIEW plz_flaechen as
SELECT ST_Area(geom) from plz;



-- 3.2. PLZ
-- st_transform rechnet die Fläche nach ETRS89 Zone 32 um (EPSG 25832) 
SELECT ST_Area(ST_Transform(geom,25832)),* from plz;

-- Welche ist die größte Fläche?
SELECT max(ST_Area(ST_Transform(geom,25832))) as flaeche from plz;

SELECT ST_Area(ST_Transform(geom,25832)) as flaeche, * from plz ORDER BY flaeche desc limit 1;


-- st_distance - Distanz zwischen Objekten
-- In welchem PLZ liegen die Punkte der Tabelle poi?
SELECT poi.*, plz.* from poi, plz
WHERE st_distance(poi.geom, plz.geom) = 0; 


-- 3.3 POI
-- Entfernung der zwei Punkte der Tabelle poi
SELECT * from poi schloss where gid = 1;

SELECT * from poi see where gid = 2;

SELECT *, st_distance(schloss.geom, see.geom) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

SELECT *, st_distance(st_transform(schloss.geom,25832), st_transform(see.geom,25832)) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

Create view line_poi as
SELECT *, st_MakeLine(schloss.geom, see.geom) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

Create VIEW linie_zwischen_poi as
SELECT schloss.gid, st_MakeLine(schloss.geom, see.geom)::geometry(linestring,4326) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;


-- Nur die Seen mit Beschriftung übertragen: 321 Stück
-- Filter in QGIS setzen: type = 'water' and name != ''
CREATE VIEW water_envelope as
SELECT st_envelope(geom) from water;

-- besser Abgabe Geometrietyp und srid
DROP VIEW water_envelope;
CREATE VIEW water_envelope as
SELECT st_envelope(geom)::geometry(polygon,4326) from water;

-- 3.4 roads
-- Länge der Straße Schlossplatz
SELECT geom, ST_AsText(geom), ST_AsEWKT(geom), ST_X(geom), ST_Y(geom) from poi;


-- Puffern der Straßen am Schlossplatz
Create view roads_buffer as
Select gid,name, 
st_buffer(geom,0.0001)::geometry(polygon,4326) as geom_buffer from roads where name = 'Schlossplatz';

CREATE TABLE poi_linie as
SELECT schloss.gid, st_MakeLine(schloss.geom, see.geom)::geometry(linestring,4326) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;


-- Validierung
SELECT * from plz where st_isvalid(geom) = false;

st_isvalidreason(geom)
st_makevalid(geom)


