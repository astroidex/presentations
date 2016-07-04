-- SQL Beispiele zum Workshop PostGIS für Einsteiger
-- FOSSGIS 2016 Astrid Emde

-- Es werden die Daten der OSGeo-Live verwendet
-- /user/data/natural_erath2/

-- Dokumente und Daten sind auf der OSGeo Workshopseite verlinkt
-- https://trac.osgeo.org/osgeo/wiki/Live_GIS_Workshop_Install

--Daten für den Workshop
-- OSM http://download.geofabrik.de/
-- OSM Austria: http://download.geofabrik.de/europe/austria-latest.shp.zip (229,9MB Stand 4.7.2016)

-- OSM Regierungsbezirk Münster http://download.geofabrik.de/europe/germany/nordrhein-westfalen/muenster-regbez-latest.shp.zip


-- PLZ von Deutschland zum Download unter
-- https://trac.osgeo.org/osgeo/wiki/Live_GIS_Workshop_Install

-- PostGIS Dokumentation
-- http://postgis.net/docs/manual-2.2/

-- PostgreSQL Dokumentation:
-- http://www.postgresql.org/docs/current/interactive/index.html

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
-- poi in Salzburg
INSERT INTO poi (name , geom) VALUES 
('Festung Hohensalzburg', 
ST_SetSRID(ST_MakePoint(13.047256,47.794967), 4326)
);

INSERT INTO poi (name , geom) VALUES 
('AGIT Salzburg', 
ST_GeometryFromText('POINT(13.060697 47.788686)', 4326)
);

INSERT INTO poi (name , geom) VALUES
('Salzburg Hauptbahnhof',
ST_SetSRID(ST_MakePoint(13.045769,47.813139), 4326)
);


-- poi in Münster
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
SELECT * from geometry_columns;

-- poi Ausgabe der Geometrie als WKT, EWKT, Lon und Lat
SELECT geom, ST_AsText(geom), ST_AsEWKT(geom), ST_X(geom), ST_Y(geom) from poi;


------------------------------------------------------------------
-- Übung 2: Natural Earth2 Provinzen
------------------------------------------------------------------
-- 2.1 QGIS SQL-Fenster oder pgAdmin SQL-Editor verwenden
-- Laden Sie die Daten NaturalEarth Daten von /user/data/mnatural_earth2/ne_10m_admin_1_states_provinces_shp.shp
-- 

-- QGIS Filter auf ne_10m_admin_1_states_provinces_shp
-- nur provinces mit, die in der Spalte admin 'Austria' stehen haben anzeigen 
admin = 'Austria'  

-- nur provinces mit, die in der Spalte admin 'Germany' stehen haben anzeigen
admin = 'Germany'

-- 'Austria' oder 'Germany'
admin = 'Austria' OR admin = 'Germany'
-- oder
admin IN ('Austria', 'Germany')


-- 2.2 Import der gefilterten Daten in die Datenbank unter dem Namen laender
-- ESPG 4326

-- SQL Editor
-- Nur Bundesland Salzburg ausgeben
SELECT * FROM laender WHERE admin = 'Austria' AND name = 'Salzburg';

-- Nur Bundesland NRW ausgeben
SELECT * FROM laender WHERE admin = 'Germany' AND name = 'Nordrhein-Westfalen';



-- 2.3 Berechung der Fläche der Länder
SELECT ST_Area(geom), * from laender;

SELECT ST_Area(ST_transform(geom,25832)) as flaeche, * from laender;

--- das größte Bundesland?
SELECT ST_Area(ST_transform(geom,25832)) as flaeche, * from laender ORDER BY flaeche DESC LIMIT 1;


-- 2.4 In welchem Bundesland liegen die pois?
SELECT poi.*, l.* from poi, laender l
WHERE st_distance(poi.geom, l.geom) = 0; 


-- 2.5 ST_UNION - Vereinigen der Bundeslaender
Create view austria as 
Select 1, st_union(geom) as geom from laender where admin = 'Austria';

Create view brd as 
Select 1, st_union(geom) as geom from laender where admin = 'Germany';


------------------------------------------------------------------
-- Übung 3: Natural Earth2 Flüsse
------------------------------------------------------------------

-- 3.1 Import der Natural Earth2 /user/data/natural_earth2/ne_10m_rivers_lake_centerlines.shp in die Tabelle fluesse (mit gid, Geometrieindex und Angabe der Projektion EPSG 4326)
-- nur Flüsse übertragen: Filter featurecla = 'River'

-- 3.2 Anzahl der Objekte in der Tabelle fluesse
SELECT count(*) FROM fluesse;

-- 3.3 Länge der Flüsse
SELECT ST_Length(ST_transform(geom,25832)) as laenge, * from fluesse;


-- 3.4 ST_Buffer - Puffern von Daten
Create view fluesse_puffer as
Select gid,name, 
st_buffer(geom,0.0001)::geometry(polygon,4326) as geom_buffer 
from fluesse WHERE name IN ('Rhine','Donau');


------------------------------------------------------------------
-- Übung 4: Entfernung zwischen Objekten
------------------------------------------------------------------
-- QGIS SQL-Fenster oder pgAdmin SQL-Editor verwenden

-- 4.1 POI
-- Entfernung der zwei Punkte in Münster der Tabelle poi
SELECT * from poi schloss where gid = 1;

SELECT * from poi see where gid = 2;

SELECT *, st_distance(schloss.geom, see.geom) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

SELECT *, st_distance(st_transform(schloss.geom,25832), st_transform(see.geom,25832)) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;


-- 4.2 POI
-- Sicht: Linie erzeugen über ST_MakeLine
Create view line_poi as
SELECT *, st_MakeLine(schloss.geom, see.geom) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

-- Anpassung der Sicht
-- besser mit Abgabe Geometrietyp und srid -> ::geometry(linestring,4326) (:: zur Typumwandlung)
Create VIEW linie_zwischen_poi as
SELECT schloss.gid, st_MakeLine(schloss.geom, see.geom)::geometry(linestring,4326) from poi schloss, poi see where schloss.gid = 1 AND see.gid=2;

-- poi Ausgabe der Geometrie als WKT, EWKT, Lon und Lat
SELECT geom, ST_AsText(geom), ST_AsEKWT(geom), ST_X(geom), ST_Y(geom) from poi;




------------------------------------------------------------------
-- Übung 5: Weitere Funktionen
------------------------------------------------------------------

-- 5.1 Funktion Envelope
DROP VIEW fluesse_envelope;
CREATE VIEW fluesse_envelope as
SELECT st_envelope(geom)::geometry(polygon,4326) from fluesse;



-- 5.2 Validierung von Geometrien
SELECT * from laender where st_isvalid(geom) = false;

-- st_isvalidreason(geom) gibt den Grund für die Ungültigkeit aus (z.B. Self-intersection)
SELECT st_isvalidreason(geom), * from laender where st_isvalid(geom) = false;

--  st_makevalid(geom) - Geometrien reparieren
Update laender set geom = st_makevalid(geom) where st_isvalid(geom) = false;




