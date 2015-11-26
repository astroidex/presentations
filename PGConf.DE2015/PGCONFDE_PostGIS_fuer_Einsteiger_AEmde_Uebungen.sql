-- SQL Beispiele zum Workshop PostGIS für Einsteiger (PGConf.De 2015 Hamburg) 
-- https://www.postgresql.eu/events/schedule/pgconfde2015/session/1099-workshop-einfuhrung-in-die-verwaltung-von-geodaten-in-der-postgresql-datenbank-mit-postgis/

-- Astrid Emde
-- WhereGroup
-- astrid dot emde at wheregroup dot com

-- Daten für den Workshop
-- OSGEO-Live unter: /home/user/data/natural_earth2/

-- Kommentare erfolgen über --

------------------------------------------------------------------
-- Übung 1: pgAdmin III
------------------------------------------------------------------

-- 1.1 Anlegen einer Datenbank mit PostGIS Erweiterung

CREATE DATABASE workshop;

--Wechseln zur Datenbank workshop

CREATE EXTENSION postgis;

-- 1.2 Tabelle anlegen
-- poi - eine einfache Tabelle
CREATE TABLE poi (
   gid serial,
   name varchar,
   geom geometry( point , 4326 ),
  CONSTRAINT pk_poi_gid PRIMARY KEY (gid)
);

-- Information zu EPSG Codes
-- http://spatialreference.org


-- 1.3 Füllen der Tabelle poi mit Daten
INSERT INTO poi (name , geom) VALUES 
('Aasee Münster', 
ST_GeometryFromText('POINT(7.62517 51.95616)', 4326)
);

INSERT INTO poi (name , geom) VALUES 
('Lindner Hotel am Michel', 
ST_GeometryFromText('POINT(9.9782746 53.551242)', 4326)
);

INSERT INTO poi (name , geom) VALUES 
('St. Pauli Elbtunnel Landungsbrücke', 
ST_GeometryFromText('POINT(9.9664926 53.5458621)', 4326)
);

INSERT INTO poi (name , geom) VALUES 
('St. Pauli Elbtunnel Schanzenweg', 
ST_GeometryFromText('POINT(9.9664308 53.5418788)', 4326)
);


-- 1.4 Anzeige der Daten (SQL Editor oder Tabellensymbol)
SELECT *, ST_AsText(geom) from poi;


-- 1.5 Anzeige der Sicht geometry_column
SELECT * from geometry_columns;


-- 1.6 poi Ausgabe der Geometrie als WKT, EWKT, Lon und Lat
SELECT geom, ST_AsText(geom), ST_AsEWKT(geom), ST_X(geom), ST_Y(geom) from poi;


-- 1.7 GiST - Anlegen eines Geometrieindex
CREATE INDEX gist_poi_geom
  ON public.poi
  USING gist
  (geom);


-- 1.8 QGIS starten und Verbindung zur Datenbank workshop aufbauen
-- Anzeige der poi in der Karte
-- Start - Geospatial - Desktop GIS - QGIS


------------------------------------------------------------------
-- Übung 2: QGIS: Import von Daten über QGIS DB Manager
--          Daten: Natural Earth2
------------------------------------------------------------------
--2.1 QGIS SQL-Fenster und pgAdmin SQL-Editor verwenden

-- Natural Earth2: Vektordaten in QGIS laden /home/user/data/natural_earth2/ne_10m_admin_1_states_provinces_shp

-- 2.2 QGIS DB Manager öffnen - Verbindung zur DB workshop aufbauen
-- 2.3 Import der Daten unter dem Namen laender in die Datenbank workshop
-- ESPG 4326

-- 2.4 Laden der Tabelle laender in QGIS (drag & drop aus DB Manager)

-- 2.5 Kontextmenü Themenbaum -> Filter: Nur Hamburg anzeigen
name = 'Hamburg'

------------------------------------------------------------------
-- Übung 3: Import von Daten über andere Programme
--          Natural Earth2
------------------------------------------------------------------
-- Es liegen noch zahlreiche weitere Toools für den Import und Export von Vektordaten vor. 
-- shp2pgsql, shp2pgsql-gui, ogr2ogr, GeoKettle

-- 3.1 shp2pgsql (Teil von PostGIS)
cd /home/user/data/natural_earth2/
shp2pgsql -I -s 4326 -W Latin1 ne_10m_rivers_lake_centerlines.shp fluesse | psql -U user workshop


-- 3.2. shp2pgsql-gui (Teil von PostGIS)
-- Start der Anwendung shp2pgsql-GUI
shp2pgsql-gui


-- 3.3 ogr2ogr (GDAL/OGR Bibliothek - derzeit liegen 84 Vektordatentreiber vor)
cd /home/user/data/natural_earth2/
ogr2ogr -f PostgreSQL PG:"host=localhost dbname=workshop user=user options='-c client_encoding=UTF8'" ne_10m_admin_1_states_provinces_shp.shp -nln provinces_mit_ogr2gr -a_srs EPSG:31467 -nlt MULTIPOLYGON


-- 3.4 Öffnen Sie QGIS und laden Sie die importierten Daten


------------------------------------------------------------------
-- Übung 4: PostGIS - Einsatz räumlicher Funktionen 
--          
------------------------------------------------------------------
-- pgAdmin: SQL Editor

-- 4.1 Nur Hamburg ausgeben
SELECT * FROM laender WHERE admin = 'Germany' AND name = 'Hamburg'

-- 4.2 Berechung der Fläche der Länder von Deutschland
SELECT ST_Area(geom), * from laender WHERE admin = 'Germany';

SELECT ST_Area(ST_transform(geom,25832)) as flaeche, * from laender WHERE admin = 'Germany';

--- 4.3 das größte Bundesland von Deutschland?
SELECT ST_Area(ST_transform(geom,25832)) as flaeche, * from laender WHERE admin = 'Germany'
ORDER BY flaeche DESC LIMIT 1;

-- 4.4. In welchem Bundesland liegen die Punkte der Tabelle poi?
SELECT poi.*, l.name, l.admin from poi, laender l
WHERE ST_Distance(poi.geom, l.geom) = 0; 


-- 4.5 ST_UNION - Vereinigen der Bundeslaender von Germany
Create view brd as 
Select 1 as gid, ST_Union(geom) as geom from laender where admin = 'Germany';


-- 4.6 ST_Buffer - Puffern von Daten
Create view fluesse_puffer as
Select gid, name, 
ST_Multi(ST_Buffer(geom,0.0002))::geometry(multipolygon,4326) as geom_buffer 
from fluesse WHERE name = 'Elbe';


-- 4.7 ST_Intersection - Verschneiden von Objekten
Create or Replace View fluesse_intersection as
Select f.gid, f.name as fluss, l.name as bundesland, 
ST_Multi(ST_Intersection(st_buffer(f.geom,0.002),l.geom))::geometry(multipolygon,4326) as geom,
ST_Length(ST_Transform(ST_Multi(ST_Intersection(f.geom,l.geom))::geometry(multilinestring,4326),25832)) as laenge
from fluesse f, laender l 
WHERE f.name = 'Elbe' and l.name = 'Hamburg';


------------------------------------------------------------------
-- Übung 5: 
------------------------------------------------------------------

-- 5.1 POI - Entfernung zweier Punkte der Tabelle poi
SELECT * from poi h where gid In (2,3);
SELECT *, st_distance(h.geom, e.geom) from poi h, poi e where h.gid = 2 AND e.gid = 3;

SELECT *, st_distance(st_transform(h.geom,25832), st_transform(e.geom,25832)) 
from poi h, poi e where h.gid = 2 AND e.gid= 3;


-- 5.2 ST_MakeLine zum Erzeugen von Linien aus zwei Punkten
Create view linie_poi as
SELECT h.gid, h.name || ' ' || e.name as name , st_MakeLine(h.geom, e.geom) from poi h, poi e where h.gid = 2 AND e.gid = 3;

Select *, st_AsEwkt(st_makeline) from linie_poi;


-- 5.3 Type Cast - genaue Angabe des Geometrietyps und SRID (Stichwort - typmod)
Create VIEW linie_zwischen_poi as
SELECT h.gid, h.name || ' ' || e.name as name , 
ST_MakeLine(h.geom, e.geom)::geometry(linestring,4326) as geom 
from poi h, poi e 
where h.gid = 2 AND e.gid = 3;

Select *, st_AsEwkt(geom) from linie_zwischen_poi;


-- 5.4 ST_Envelope - kleinstes Rechteck um Geometrie
Create VIEW linie_envelope as
SELECT h.gid, ST_Envelope(st_MakeLine(h.geom, e.geom))::geometry(polygon,4326) as geom 
from poi h, poi e 
where h.gid = 2 AND e.gid = 3;


------------------------------------------------------------------
-- Übung 6: Prüfung der Gültigkeit von Geometrien und Bereinigung
--          Validierung
------------------------------------------------------------------

-- 6.1 St_IsValidDetail und St_IsValid zur Prüfung der Gültigkeit der Geometrien
-- Bsp. laender: Ausgabe von 2 fehlerhaften Flächen: verfügen über eine Self-Intersection
SELECT ST_IsValidDetail(geom), ST_IsValid(geom), * from laender where ST_isvalid(geom) = false;


-- 6.2 Reparatur der Daten: St_MakeValid zur Bereinigung der Flächen
Update laender SET geom = ST_MakeValid(geom) where  st_isvalid(geom) = false;


------------------------------------------------------------------
-- Übung 7: Verwendung des Datentyps geography 
--         zur Berechung auf dem Spheroid
------------------------------------------------------------------
-- Import der Daten ne_10m_populated_places.shp in die Tabelle orte
cd /home/user/data/natural_earth2/
shp2pgsql -I -s 4326 -W Latin1 ne_10m_populated_places.shp orte | psql -U user workshop


-- Berechnung der Entfernung zwischen Hamburg und New York 6.130 Kilometer

-- 7.1 Filter auf Hamburg und New York
name = 'Hamburg' OR name = 'New York'

-- 7.2 Berechnung der Entfernung von Hamburg nach New York - Verwendung geometry
-- Verwendung Geometry - nicht zu empfehlen bei großen Entfernungen
SELECT h.name, n.name , ST_Distance(st_transform(h.geom,3785), st_transform(n.geom,3785)) FROM orte h, orte n
WHERE h.name = 'Hamburg' AND n.name = 'New York';
--Ergebnis: 9583756.9397031

-- Verwendung Geography
SELECT h.name, n.name , ST_Distance(h.geom::geography, n.geom::geography) FROM orte h, orte n
WHERE h.name = 'Hamburg' AND n.name = 'New York';
-- Ergebnis: 6142373.63947616


------------------------------------------------------------------
-- Übung 8: Kreise und Kreisbögen
--        
------------------------------------------------------------------
CREATE TABLE kreise (
   gid serial,
   name varchar,
   geom geometry( multicurve , 4326 ),
  CONSTRAINT pk_kreise_gid PRIMARY KEY (gid)
);

Insert INTO kreise (name, geom) Values
('MULTICURVE', ST_Geomfromtext('MULTICURVE( (0 0, 5 5), CIRCULARSTRING(4 0, 4 4, 8 4) )',4326));

Insert INTO kreise (name, geom) Values
('CIRCULARSTRING', ST_Geomfromtext('MULTICURVE( CIRCULARSTRING(0 0, 4 0, 4 4, 0 4, 0 0) )',4326));


