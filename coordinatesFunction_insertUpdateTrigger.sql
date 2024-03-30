
-- FUNCTION

-- Funktion, die als Parameter den Namen einer Stadt bekommt und die X- und Y-Koordinate ausgibt 
CREATE OR REPLACE FUNCTION koordinatenAusgeben(stadt character)    		-- or 'text'
RETURNS text                           						-- or 'character'
AS 
$$
SELECT city_name || ': ' || ST_Y(geom) || ', ' || ST_X(geom)
FROM cities 
WHERE city_name=stadt; 
$$
LANGUAGE sql; 

SELECT koordinatenAusgeben('Kyoto');  



--------------------------------------------------------------------------


-- TRIGGER

-- Für Trigger : Funktion definieren  
CREATE OR REPLACE FUNCTION update_x_and_y()
RETURNS TRIGGER
AS
$$
BEGIN 
UPDATE cities SET lat=ST_Y(geom), lon=ST_X(geom) WHERE gid=NEW.gid;     -- nur neu-hinzugefügte
RETURN NULL;                                         			-- nichts wird zurückgegeben
END; 
$$
LANGUAGE plpgsql;							-- SQL-Dialekt : PL/SQL (Procedural Language/Structured Query Language) = prozedurale Programmiersprache => gibt auch objektorientierte


-- INSERT Trigger erstellen 
	--> beim INSERT in einer bestimmten Tabelle (cities) soll die Funktion update_x_and_y aufgerufen werden 

--DROP TRIGGER IF EXISTS koordinaten_insert_trigger ON cities; 

CREATE TRIGGER koordinaten_insert_trigger
AFTER INSERT ON cities 
FOR EACH ROW                                       			-- für jede Zeile ein FunktionsAufruf
EXECUTE PROCEDURE update_x_and_y(); 


-- UPDATE Trigger 
	--> bei jedem Update einer bestimmten Spalte wird die Funktion aufgerufen 

--DROP TRIGGER IF EXISTS koordinaten_update_trigger ON cities; 

CREATE TRIGGER koordinaten_update_trigger
AFTER UPDATE OF geom 
ON cities
FOR EACH ROW
EXECUTE PROCEDURE update_x_and_y();
