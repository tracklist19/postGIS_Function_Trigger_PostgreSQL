-----------------------------------------------------------------------------------------------------------------------------
-- Anzahl, FlächenSumme und prozentuale FlächeAnteile der Ackerlandfeldblöcke kleiner und größer des Flächen-Durchschnitts --
-----------------------------------------------------------------------------------------------------------------------------


SELECT
	-- Anzahl Über-&Unter-DurschnittsFlächen 
	COUNT(beavg_a_fb_al) AS nr_beavg_a_fb_al,  
	COUNT(abavg_a_fb_al) AS nr_abavg_a_fb_al, 
	COUNT(area_qm)		 AS nr_a_fb_al, 
	(COUNT(beavg_a_fb_al) + COUNT(abavg_a_fb_al)) AS check_nr,   

	-- Summen der Flächen über und unter Durchschnitt 
	SUM(iii_2_1.beavg_a_fb_al) AS sum_beavg_a_fb_al, 
	SUM(iii_2_2.abavg_a_fb_al) AS sum_abavg_a_fb_al, 
	SUM(area_qm) 		 AS sum_a_fb_al, 
	(SUM(iii_2_1.beavg_a_fb_al) + SUM(iii_2_2.abavg_a_fb_al)) AS check_sum,  
	
	-- Prozentuale Anteile der Über-&Unter-Durschnitt-FlächenSummen an der GesamtFläche 
	(SUM(iii_2_1.beavg_a_fb_al) * 100 / SUM(area_qm)) AS pct_beavg_a_fb_al, 
	(SUM(iii_2_2.abavg_a_fb_al) * 100 / SUM(area_qm)) AS pct_abavg_a_fb_al, 
	((SUM(iii_2_1.beavg_a_fb_al) * 100 / SUM(area_qm)) + (SUM(iii_2_2.abavg_a_fb_al) * 100 / SUM(area_qm))) AS check_pct
	
FROM import_shp2p.fb_extrahiert_1_shp2p

LEFT JOIN 
	(-- Flächen kleiner als der Durchschnitt der Flächen der Ackerlandfeldblöcke 
		SELECT
			area_qm AS beavg_a_fb_al, 									-- below average 
			--avg_a_fb_al,												-- average 
			fb_id
		FROM 
			(	
				SELECT 
					--SUM(area_qm) sum_a_fb_al,
					--MIN(area_qm) min_a_fb_al,
					--MAX(area_qm) max_a_fb_al,
					AVG(area_qm) avg_a_fb_al
				FROM import_shp2p.fb_extrahiert_1_shp2p 
				WHERE bodennutzu='AL' 
			) AS iii_1, 
				 import_shp2p.fb_extrahiert_1_shp2p 

		WHERE bodennutzu='AL' 
		  AND area_qm < avg_a_fb_al 
	) AS iii_2_1 
ON import_shp2p.fb_extrahiert_1_shp2p.fb_id = iii_2_1.fb_id 

LEFT JOIN 
	(-- Flächen größer als der Durchschnitt der Flächen der Ackerlandfeldblöcke 	
		SELECT
			area_qm AS abavg_a_fb_al, 									-- above average
			--avg_a_fb_al, 												-- average 
			fb_id
		FROM 
			(	
				SELECT 
					--SUM(area_qm) sum_a_fb_al, 
					--MIN(area_qm) min_a_fb_al, 
					--MAX(area_qm) max_a_fb_al, 
					AVG(area_qm) avg_a_fb_al
				FROM import_shp2p.fb_extrahiert_1_shp2p 
				WHERE bodennutzu='AL' 
			) AS iii_1, 
				 import_shp2p.fb_extrahiert_1_shp2p 

		WHERE bodennutzu='AL' 
		  AND area_qm > avg_a_fb_al 
	) AS iii_2_2 
ON import_shp2p.fb_extrahiert_1_shp2p.fb_id = iii_2_2.fb_id 

WHERE bodennutzu='AL'
;
