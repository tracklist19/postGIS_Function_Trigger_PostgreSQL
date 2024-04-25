-- Koordinaten-Identische/"Übereinander-Liegende" Punkte aus einem Datensatz entfernen 
	--> AusgangPunkt_1: (Multi-)Point, (Multi-)Linestring, (Multi-)Polygon 
	--> AusgangPunkt_2: Polygone (Start-&End-Punkt sind jeweils identisch) 
-- Vergleich: ST_RemoveRepeatedPoints <-> Identifikation & DeSelektion per JOINs 
----------------------------------------------------------------------------------------------------------------------------------------


-- (Multi-)Point, (Multi-)Linestring, (Multi-)Polygon 

	--> Removal Doppelter Punkte bezieht sich nicht auf den kompletten Datenbestand, sondern jeweils auf einen einzelnen Datensatz/Geometrie/MultiGeometrie-Part 

	SELECT ST_AsText(geom)
		 , geom 
		 , ST_AsTExt(ST_RemoveRepeatedPoints(geom)) ST_RemoveRepeatedPoints
		FROM (
			VALUES  (ST_GeomFromText('POINT(1 1)')), 
				    (ST_GeomFromText('POINT(1 1)')),											-- Entfernt identischen Punkt in anderem Datensatz nicht 
					(ST_GeomFromText('MULTIPOINT(1 1, 1 1)')), 									-- Entfernt identischen MultiPunkt-Part  
					(ST_GeomFromText('LINESTRING(1 1, 1 1, 2 2, 3 3)')), 								-- Entfernt identischen Punkt innerhalb einer Linie  
					(ST_GeomFromText('MULTILINESTRING((1 1, 1 1, 2 2, 3 3), (4 4, 5 5), (4 4, 5 5))')), 				-- Entfernt identischen Punkt innerhalb eines MultiLine-Parts, nicht einen identischen MultiLine-Part in Gänze 
					(ST_GeomFromText('POLYGON((1 1, 1 1, 2 1, 2 2, 1 2, 1 1))')), 							-- Entfernt identischen Punkt innerhalb eines Polygons/MultiPolygon-Parts, 
					(ST_GeomFromText('MULTIPOLYGON(((1 1, 1 1, 2 1, 2 2, 1 2, 1 1)), ((1 1, 2 1, 2 2, 1 2, 1 1)), ((1 1, 2 1, 2 2, 1 2, 1 1)))')) -- nicht einen identischen MultiPolygon-Part in Gänze
			) poi (geom)




-- Zum StartPunkt identischen End-Punkt von Polygonen entfernen 

	-- Test-Geometrien erstellen 										  					-- DROP TABLE rrp ; 
	CREATE TEMP TABLE rrp (id int, typ varchar(15), geom geometry(MultiPolygon)) ;

	INSERT INTO rrp (id, typ, geom) 
		VALUES -- Geometrien   ;   per VALUES auch ohne INSERT anzeigbar 
			  (1, 'Karo1', ST_Multi(ST_Buffer(ST_GeomFromText('POINT(1.5 0.5)'), 0.55, 'quad_segs=1')))	
			, (2, 'Octagon1', ST_Multi(ST_Buffer(ST_GeomFromText('POINT(3.5 0.5)'), 0.55, 'quad_segs=2'))) 
			, (3, 'Dreieck1', ST_Multi(ST_GeomFromText('POLYGON((4.4 0, 5.6 0, 5.0 0.6, 4.4 0))'))) 
			, (4, 'Quadrat2', ST_Multi(ST_GeomFromText('POLYGON((0 1, 1 1, 1 2, 0 2, 0 1))'))) 
			, (5, 'Fünfeck1', ST_Multi(ST_GeomFromText('POLYGON((2.3 0.9, 2.7 0.9, 3.1 1.6, 2.5 2.1, 1.9 1.6, 2.3 0.9))'))) 
			, (6, 'Karo2', ST_Multi(ST_Buffer(ST_GeomFromText('POINT(4.5 1.5)'), 0.55, 'quad_segs=1'))) ; 

	SELECT * FROM rrp ; 


	-- ST_RemoveRepeatedPoints 

		--> "Zerstört" keine Polygone: Entfernt nicht Start-|End-Punkt 
		--> Übereinanderliegende Punkte entfernbar mithilfe ST_Points, welches MultiPoints aus Polygonen erzeugt 

		SELECT id, typ, geom 
			 -- Kein Effekt auf (Multi-)Polygone : Start-|End-Punkt bleibt erhalten 
			 , ST_RemoveRepeatedPoints(geom) 
			 , 		ST_AsText(ST_RemoveRepeatedPoints(geom)) 
			 -- ST_Points erzeugt MultiPoint aus Polygon 
			 , ST_GeometryType(ST_Points(geom)) 
			 , ST_AsText(ST_Points(geom)) 
			 -- ST_RemoveRepeatedPoints entfernt doppelte Punkte aus MultiPoint 
			 , ST_AsText(ST_RemoveRepeatedPoints(ST_Points(geom)))
			 , '' " "
		FROM rrp ; 						 


	-- RemovePoints per JOINs  
		WITH dumped_points AS (
		-- Punkte dumpen 
		SELECT id, typ  
			, (ST_DumpPoints(geom)).path path_point 											-- For a (Multi-)POLYGON the paths are {(h,)i,j} where (h is the Number of the MultiPolygon-Part,) i is the ring number (1 is outer; inner rings follow) and j is the coordinate position in the ring. 
			, (ST_DumpPoints(geom)).geom geom_point 	
			FROM rrp ) 
		SELECT dumped_points.id , dumped_points.typ , dumped_points.path_point , dumped_points.geom_point , 
			   t1.id id_t1 , t1.typ	typ_t1 , t1.path_point path_point_t1 , t1.geom_point geom_point_t1 ,  
			   t2.id id_t2 , t2.typ typ_t2 , t2.path_point path_point_t2 , t2.geom_point geom_point_t2 					--> t1.path_point enthält StartPunkt, t2.path_point enthält die EndPunkt jedes Polygons 
			-- Identische Punkte ggü-stellen 
			FROM dumped_points t1 
			INNER JOIN dumped_points t2 
				ON t1.id = t2.id 											-- Nur jeweils ein Polygon betrachten 
					AND t1.path_point < t2.path_point  								-- Start-&End-Punkt nicht 2mal pro Polygon ggü-stellen 
					--AND ST_Equals(t1.geom_point, t2.geom_point)						-- 6 
					AND t1.geom_point = t2.geom_point							-- 6   ;   SAME as ST_Equals 
			-- End-Punkte allen Punkten ggü-stellen 
			RIGHT JOIN dumped_points 
				ON dumped_points.id = t2.id AND dumped_points.path_point = t2.path_point 			-- 34 --> Alle Polygon-bildenden Punkte 
			WHERE t2.id IS NULL ; 											-- 28 --> ohne EndPunkte --> 34 dumped_points -6 End-Punkte = 28 

