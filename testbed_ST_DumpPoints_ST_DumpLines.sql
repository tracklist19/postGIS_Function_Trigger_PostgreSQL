-- Polygone in ihre EckPunkte|LinienSegmente zerlegen 
	--> ST_DumpPoints | ST_DumpSegments (ab PostGIS 3.2.0) 
	--> ST_DumpSegments-Nachbau: LinienSegmente ermitteln durch JOIN & ST_MakeLine
----------------------------------------------------------------------------------------------------------------------------------------

-- Test-Geometrien erstellen 

	CREATE TEMP TABLE dpdl (id int, typ varchar(15), geom geometry(MultiPolygon)) ;

	INSERT INTO dpdl (id, typ, geom) 
		VALUES -- Geometrien
			  (1, 'Karo1', ST_Multi(ST_Buffer(ST_GeomFromText('POINT(1.5 0.5)'), 0.55, 'quad_segs=1')))	
			, (2, 'Octagon1', ST_Multi(ST_Buffer(ST_GeomFromText('POINT(3.5 0.5)'), 0.55, 'quad_segs=2'))) 
			, (3, 'Dreieck1', ST_Multi(ST_GeomFromText('POLYGON((4.4 0, 5.6 0, 5.0 0.6, 4.4 0))'))) 
			, (4, 'Quadrat2', ST_Multi(ST_GeomFromText('POLYGON((0 1, 1 1, 1 2, 0 2, 0 1))'))) 
			, (5, 'Fünfeck1', ST_Multi(ST_GeomFromText('POLYGON((2.3 0.9, 2.7 0.9, 3.1 1.6, 2.5 2.1, 1.9 1.6, 2.3 0.9))'))) 
			, (6, 'Karo2', ST_Multi(ST_Buffer(ST_GeomFromText('POINT(4.5 1.5)'), 0.55, 'quad_segs=1'))) ; 

	SELECT * FROM dpdl ; 


-- Linien extrahieren 

	-- ST_DumpSegments : erst ab PostGIS 3.2.0
		SELECT id, typ, geom			
			, (ST_DumpSegments(geom)).path path_line 
			, (ST_DumpSegments(geom)).geom geom_line 
			FROM dpdl ; 


	-- LinienSegmente aus PunktPaaren erzeugen  

		-- Punkte extrahieren : ST_DumpPoints 
			CREATE TEMP TABLE dumped_points AS
				SELECT id, typ, geom
					, (ST_DumpPoints(geom)).path path_point 				-- For a (Multi-)POLYGON the paths are {(h,)i,j} where (h is the Number of the MultiPolygon-Part,) i is the ring number (1 is outer; inner rings follow) and j is the coordinate position in the ring. 
					, (ST_DumpPoints(geom)).geom geom_point 	
					FROM dpdl ) 

		-- PunktPaare ggü-stellen & Linien bauen 				
			SELECT d1.id	   , d1.path_point			     , d1.geom_point 
				 , d2.id id_d2 , d2.path_point path_point_d2 , d2.geom_point geom_point_d2 
				 , d1.id||'__'||d1.path_point[3]||'_'||d1.path_point[3]+1 id_line 		-- ID gibt die beinhaltende Geometrie wieder, sowie Punkte aus der betreffende Linie gebaut wird  
				 , ST_MakeLine(d1.geom_point, d2.geom_point) geom_line
				FROM dumped_points d1 
				INNER JOIN dumped_points d2 
					ON d1.id = d2.id 										-- Stellt Zuordnung zur jeweilgen Geometrie sicher 
					AND d1.path_point[1] = d2.path_point[1]					-- Hier zwar redundant, da für alle vorhandenen Geometrien gleich 1   (Da nirgends mehr als ein MultiPolygon-Part vorhanden) 
					AND d1.path_point[2] = d2.path_point[2]					-- Hier zwar redundant, da für alle vorhandenen Geometrien gleich 1   (Da nirgends Innere_Ringe vorhanden) 
					AND d1.path_point[3]+1 = d2.path_point[3]				-- Ermittelt einen Punkt und einen weiteren Punkt dessen KoordinatenPosition (innerhalb des Polygons) die nächst-höhere ist   (So dass aus den entstehenden PunktPaaren jeweils eine Linie entstehen kann)   
				;																	--> Alle Punkte innerhalb eines Polygons werden abgedeckt, allerings keine PunktPaar-Ermittlung zwischen Letztem&Erstem Punkt: a) Sind identisch; b) keine Linie kann gebaut werden; c) alle PunktPaare zur Erzeugung der Polygon-bildenden Linien sind bereits ermittlet 
																			-- 28 : Pro Geometrie wird so jeweils das PunktPaar vom letzten zum ersten Punkt nicht betrachtet : Wäre unnötig, da beide Punkte identisch 
																						--> Sonst wäre Anzahl_PunktPaare pro Geometrie identisch mit Anzahl_Punkte pro Geometrie 
																						--> So ergeben sich pro Geometrie ein PunktPaar weniger als es Punkte gibt, insgesamt also: 28 PunktPaare ; PLUS 6 fehlende[1 je 6 Geometrien] IST_GLEICH 34[GesamtAnzahl_Punkte/aufeinanderfolgenderPunktpaare(pro_Geometrie)] 
				
