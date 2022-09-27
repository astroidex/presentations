QGIS Anwendertreffen 2022 Essen & Online

https://qgis.de/doku.php/site/anwendertreffen/start


Vortrag: QGIS und PostgreSQL/PostGIS - tolle Möglichkeiten des Zusammenspiels 

Astrid Emde
WhereGroup GmbH Germany
https://wheregroup.com

astrid.emde@wheregroup.com
https://www.osgeo.org/member/astrid-emde/
https://twitter.com/astroidex

WhereGroup GmbH Germany
https://wheregroup.com

FOSS Academy 
https://www.foss-academy.com/

[![Creative Commons License](http://i.creativecommons.org/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.de)

PDF Ansicht der Präsemtation (ohne Videos)
https://raw.githubusercontent.com/astroidex/presentations/master/QGIS2022/QGIS_Anwendertreffen_2022_QGIS_PostGIS_Moeglichkeiten_Emde.pdf


Download der Präsentation als odp (Libre Office Datei) mit Videos
https://github.com/astroidex/presentations/raw/master/QGIS2022/QGIS_Anwendertreffen_2022_QGIS_PostGIS_Moeglichkeiten_Emde.odp


Videos aus der Präsentation
https://github.com/astroidex/presentations/tree/master/QGIS2022/videos


# Beispiele

im Verzeichnis beispiele befindet sich eine Beispieldatenbank bonn (Datei bonn.backup).

Die bonn Datenbank enthält:

- Ausschnitt Bonn mit Flurstücken und Gebäuden (ALKIS)
- Bänke und Bäume aus OpenStreetmap via QGIS Plugin QuickOSM
- eigene Tabellen 
- QGIS Styles
- QGIS Projekt bonn_baeume

Die Datenbank kann über restore auf dem eigenen Symstem importiert werden (mit Option --no-owner). Dabei muss die Datenbank bonn zuerst angelegt werden.

Create database bonn;
pg_restore --host "localhost" --port "5432" --no-owner --username "postgres"  --dbname "bonn" --verbose ".beispiele/bonn.backup"


Die .pg_service.conf enthält die Verbindungsangaben zur Datenbank (passt zur Verwendung mit OSGeoLive). 
Siehe auch Blogartikel WhereGroup https://wheregroup.com/blog/details/einfache-verbindung-von-postgresql-postgis-datenbanken-mit-qgis-mittels-mit-pg-serviceconf/

In der Datei ./beispiel/beispiele.sql sind ein paar SQL aufgeführt. Diese befinden sich aber auch in der Datenbanksicherung bonn.backup.


# Fragen

Im folgenden Abschnitt sollen die Fragen, die nach dem Vortrag gestellt wurden, beantwortet werden.


Frage: Wie aufwendig ist die Migration von Oracle nach PostGIS?
- Antwort: https://wiki.postgresql.org/wiki/Oracle_to_Postgres_Conversion
org2ogr kann beim Umzug nach PostgreSQl/PostGIS behilflich sein.
https://gdal.org/programs/ogr2ogr.html
https://gdal.org/drivers/vector/oci.html

Frage: Gibt es eine Möglichkeit, Passwörter in der pgservice.conf verschlüsselt zu speichern?
- Antwort: die .pg_service.conf ist mit der lokalen .pgpass kombinierbar
https://www.postgresql.org/docs/12/libpq-pgpass.html

Frage: Rasterdaten in der PostgreSQL/PostGIS-Datenbank - wie performant ist das im Vergleich zur Ablage in einem normalen Dateiverzeichnis?


Frage: Bietet die Speicherung von Rasterdaten in der PostGIS-DB Vorteile bezüglich Komprimierung?


Frage: Ist über die DB-Manager in QGIS auch der Import von Shapefiles möglich?
- Antwort: ja


Frage: Ist das ALKIS-Plugin nur für NRW-ALKIS oder auch für andere Landesvermessungen kompatibel?
- Antwort: Das ALKIS Plugin kann bundesweit für das Austauschformat NAS eingesezt werden.


Frage: Lohnt sich das Anlegen einer Postgis Datenbank auch bei kleineren Datenmengen und geringen personellen Ressourcen? Falls nicht, gibt es eine "einfachere" Art der Datenhaltung, um Redundanzen zu vermeiden?
- Antwort: Wollten Sie Wert auf Mehrbenutzerfähigkeit und zentrale Datenhaltung, sowie Berechtigungen legen, lohnt sich PostgreSQL auf alle Fälle.


Frage: Wie stellt man eine Hintergrundkarte im pgAdmin GeometryViewer ein?


Frage: Ist das Restore eines Backups auch über die QGIS-DB-Verwaltung möglich?
 

Frage: Gibt es ein Plugin, das die Versionierung unterstützt?


Frage: Welcher SQL Client wird im DB Manager verwendet? Spatiallite?


Frage: Wir verwenden eine generische PostgreSQL. Gibt es eine Möglichkeit die Tabellen- und Spaltennamen im Klartext in QGIS darzustellen?