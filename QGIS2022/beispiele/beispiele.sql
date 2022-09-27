CREATE SCHEMA verkehr;


-- Funktion checkBank prüft, ob eine Bank in < 5m Entfernung vorliegt
CREATE OR REPLACE FUNCTION verkehr.checkBank(geom geometry) returns boolean
AS 
$BODY$
SELECT CASE WHEN st_distance(ST_Transform(geom,25832), $1) < 5 THEN
  true 
ELSE
  false
END 
FROM verkehr.baenke 
 ORDER BY ST_Transform(geom,25832) <-> $1 LIMIT 1;
$BODY$
LANGUAGE 'sql'; 


CREATE TABLE verkehr.baumart (
  gid serial PRIMARY KEY,
  baumart_lat varchar	
);

Insert into verkehr.baumart (baumart_lat) VALUES ('Acer campestre');
Insert into verkehr.baumart (baumart_lat) VALUES ('Betula pendula');
Insert into verkehr.baumart (baumart_lat) VALUES ('Aesculus hippocastanum');
Insert into verkehr.baumart (baumart_lat) VALUES ('Pinus nigra');
Insert into verkehr.baumart (baumart_lat) VALUES ('Ginkgo biloba');
Insert into verkehr.baumart (baumart_lat) VALUES ('Robinia pseudoacacia');

--Drop function verkehr.checkEntfernungGebaeude(geom geometry) CASCADE;
CREATE OR REPLACE FUNCTION verkehr.checkEntfernungGebaeude(geom geometry) 
returns float
 AS 'SELECT ST_Distance(ST_Transform(wkb_geometry,25832),$1) FROM ax_gebaeude ORDER BY ST_Transform(wkb_geometry,25832) <-> $1 LIMIT 1;' 
LANGUAGE 'sql'; 


--Drop table verkehr.neupflanzungen;
CREATE TABLE verkehr.neupflanzungen
(
    gid serial PRIMARY KEY,
    fkey_baumart_id integer NOT NULL,
    datum_vorschlag date DEFAULT date(now()),
    datum_geplante_pflanzung date,
    entfernung_gebaeude double precision,
    bank_liegt_vor boolean,
    geom geometry(Point,25832),
    flurstueck character varying COLLATE pg_catalog."default",
    CONSTRAINT neupflanzungen_pkey PRIMARY KEY (gid),
    CONSTRAINT checkentfernunggebaeude CHECK (verkehr.checkentfernunggebaeude(geom) > 5::double precision) NOT VALID
)

-- Puffer 5m 
CREATE OR REPLACE view verkehr.neupflanzungen_puffer as
SELECT gid, st_buffer(neupflanzungen.geom, 5::double precision)::geometry(Polygon,25832) AS geom
FROM verkehr.neupflanzungen;




-- Trigger füllt Infos zu Neupflanzung
-- ON INSERT UPDATE Distanz speichern
-- Distanz zu Gebäude
-- Flurstückskennzeichen
-- checkBank

--DROP FUNCTION verkehr.objectGetAdditionalInfo() CASCADE;
CREATE OR REPLACE FUNCTION verkehr.objectGetAdditionalInfo()
  RETURNS trigger AS 
 $BODY$
   DECLARE
        distanz float;
        flurstueck  varchar;
   BEGIN
    distanz := round(verkehr.checkEntfernungGebaeude(NEW.geom)::numeric,2);
    NEW.entfernung_gebaeude := distanz;
    SELECT flurstueckskennzeichen FROM ax_flurstueck INTO flurstueck WHERE ST_WITHIN(NEW.geom,wkb_geometry);
    NEW.flurstueck := flurstueck; 
  NEW.bank_liegt_vor := verkehr.checkBank(NEW.geom);
    RAISE NOTICE 'Distanz: % Flurstück: % Bank: %' ,  distanz, flurstueck, NEW.bank_liegt_vor;
    
    RETURN NEW; 
   END
$BODY$
 LANGUAGE plpgsql;

--Drop trigger baeumeOnInsertOrUpdateGetInfo ON verkehr.baeume;
CREATE TRIGGER neupflanzugenOnInsertOrUpdateGetInfo
  BEFORE INSERT OR UPDATE
  ON verkehr.neupflanzungen
  FOR EACH ROW
  EXECUTE PROCEDURE verkehr.objectGetAdditionalInfo(geom);

