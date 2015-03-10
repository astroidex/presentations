-- SQL Beispiele zum Workshop PostGIS für Einsteiger
-- http://www.fossgis.de/konferenz/2015/programm/events/794.de.html

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


------------------------------------------------------------------
-- Übung 2: 
------------------------------------------------------------------
--2.1 QGIS SQL-Fenster oder pgAdmin SQL-Editor verwenden

CREATE OR REPLACE VIEW plz_flaechen as
SELECT ST_Area(geom) from plz;



-- 2.2. PLZ
-- st_transform rechnet die Fläche nach ETRS89 Zone 32 um (EPSG 25832) 
SELECT ST_Area(ST_Transform(geom,25832)),* from plz;

-- Welche ist die größte Fläche
SELECT max(ST_Area(ST_Transform(geom,25832))) as flaeche from plz;

SELECT ST_Area(ST_Transform(geom,25832)) as flaeche, * from plz ORDER BY flaeche desc limit 1;


-- st_distance - Distanz zwischen Objekten
-- In welchem PLZ liegen die Punkte der Tabelle poi?
SELECT poi.*, plz.* from poi, plz
WHERE st_distance(poi.geom, plz.geom) = 0; 


-- 2.3 POI
-- Entfernung der zwei Punkte der Tabelle poi
SELECT * from poi schloss where gid = 1;

SELECT * from poi see where gid = 2;

SELECT *, st_distance(schloss.geom, see.geom) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

SELECT *, st_distance(st_transform(schloss.geom,25832), st_transform(see.geom,25832)) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

Create view line_poi as
SELECT *, st_MakeLine(schloss.geom, see.geom) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

Create VIEW linie_zwischen_poi as
SELECT schloss.gid, st_MakeLine(schloss.geom, see.geom)::geometry(linestring,4326) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

-- poi Ausgabe der Geometrie als WKT, EWKT, Lon und Lat
SELECT geom, ST_AsText(geom), ST_AsEKWT(geom), ST_X(geom), ST_Y(geom) from poi;


-- Nur die Seen mit Beschriftung übertragen: 321 Stück
-- Filter in QGIS setzen: type = 'water' and name != ''
CREATE VIEW water_envelope as
SELECT st_envelope(geom) from water;

-- besser Abgabe Geometrietyp und srid
DROP VIEW water_envelope;
CREATE VIEW water_envelope as
SELECT st_envelope(geom)::geometry(polygon,4326) from water;

-- 2.4 roads
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


