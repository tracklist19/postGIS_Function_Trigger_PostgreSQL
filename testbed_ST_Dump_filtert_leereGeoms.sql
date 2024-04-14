------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
-- FRAGE : 
	-- Filtert ST_Dump leere_(ST_Empty=TRUE)_Geometrien heraus ? 					(Und notValide Geometrien?)
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------


-- Leere Geometrie erzeugen 
SELECT ST_IsEmpty(ST_Multi(ST_Buffer(ST_GeomFromText('POINT(1 1)'), -1.0)))


-- Test_Geometrien in Test-Tabelle erzeugen 
	-- MultiPolygon 	: Polygon+Loch ; Polygon ; Polygon_klein 
	-- GeometryCollection   : Point ; Line ; Polygon+Loch ; MultiPolygon(Polygon_klein ; Polygon_klein ; Polygon+Loch) 
	-- LeerGeometrien	: Negativ-GePufferte Point & Line 
	-- notValideGeometrie   : SelbstÜberschneidendes Polygon 

	-- DROP TABLE to_dump ; 
	CREATE TEMPORARY TABLE to_dump AS 
	SELECT * FROM (VALUES (1, 'a_multiPol', ST_GeometryFromText('MULTIPOLYGON(((30 10 , 50 10 , 50 30 , 30 30 , 30 10),(48 28,49 28,49 29,48 29,48 28)), 
										  ((56 34, 62 48, 84 48, 84 42, 56 34)),
										  ((53 31, 53.5 31, 53.5 32, 53 32, 53 31)))', 25833)),			   		  
			      (2, 'b_geomColl', ST_GeometryFromText('GEOMETRYCOLLECTION(POINT(-4 2), LINESTRING(-1 1 , -4 -4), 
											POLYGON((-10 -10, 0 -10, 0 -5, -10 -5, -10 -10),(-9 -9, -1 -9, -1 -6, -9 -6, -9 -9)), 
											MULTIPOLYGON(((-13 -1 , -13.5 -1 , -13.5 0 , -13 0 , -13 -1)), 
												     ((-15 -2 , -15.5 -2 , -15.5 -1 , -15 -1 , -15 -2)),
												     ((0 0 , 20 0 , 20 20 , 0 20 , 0 0),(18 18,19 18,19 19,18 19,18 18))))', 25833)), 
			      (3, 'c_singlePol', ST_GeometryFromText('POLYGON((60 -10, 70 -10, 70 -5, 60 -5, 60 -10))', 25833)),
			      --(4, 'd_notEmptyPoint', ST_GeometryFromText('POINT(40 5)', 25833)),					-- nicht_leer, ungePuffert 
			      (4, 'd_emptyPointBuff', ST_Buffer(ST_GeometryFromText('POINT(40 5)', 25833), -1.0)),
			      --(5, 'e_notEmptyLine', ST_GeometryFromText('LINESTRING(30 0, 50 0)', 25833)),				-- nicht_leer, ungePuffert 
			      (5, 'e_emptyLineBuff', ST_Buffer(ST_GeometryFromText('LINESTRING(30 0, 50 0)', 25833), -1.0)),
			      (6, 'f_emptyMultiLineBuff', ST_Multi(ST_Buffer(ST_GeometryFromText('LINESTRING(30 0, 50 0)', 25833), -1.0))),
			      (7, 'g_partlyEmptyMultiPol', ST_GeometryFromText('MULTIPOLYGON('||right(ST_AsText(ST_Buffer(ST_GeometryFromText('LINESTRING(30 0, 50 0)', 25833), -1.0)),-7)||', '||right(ST_AsText(ST_Buffer(ST_GeometryFromText('LINESTRING(30 -10, 50 -10)', 25833), 1.0)),-7)||')', 25833)),  -- ST_Collect: Aggregatfunktionen sind in VALUES nicht erlaubt 
			      (8, 'h_notValidPol', ST_GeometryFromText('POLYGON((-10 -20, 0 -20, 0 -15, 10 -15, -10 -20),(-9 -19, -1 -19, -1 -14, 9 -14, -9 -19))', 25833))
		       ) AS t1 (gid, name, geom) ; 
	

	SELECT * , ST_IsEmpty(geom), ST_IsValid(geom) FROM to_dump ; 
	

-- Auswirkung von ST_Dump auf LeereGeom & notValideGeom 

	--> Leere Geometrien werden ignoriert/nicht gedumped 
		--> Leere MultiGeometrie-Parts werden hingegen gedumped, allerdings nur falls sich zusätzl.noch notEmpty MultiGeometrie-Parts in der MultiGeometrie befinden 
				-- (Nur aus einem leeren MultiGeometrie-Part bestehende MultiGeometrien werden ebenso ignoriert/nicht gedumpt) 
	--> notValide Geometrien werden in den Dump übernommen 

	WITH dumped_geom AS (
		SELECT gid, name 
			 , (ST_Dump(geom)).path path_dump 
			 , (ST_Dump(geom)).geom geom_dump 
			FROM to_dump 
		) 
		SELECT * , ST_IsEmpty(geom_dump), ST_IsValid(geom_dump)
			FROM dumped_geom
		; 
