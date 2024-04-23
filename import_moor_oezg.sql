------------------------------------------------------------------------
--  IMPORT : Moor_OEzg  --
------------------------------------------------------------------------


SET search_path TO forst,public ; 


------------------------------------------------------------------------
-- CREATE_TABLE 


--DROP TABLE IF EXISTS fos_moor_pruef 

CREATE TABLE fos_moor_pruef (
	gid serial NOT NULL, 
	nr integer, 
	name character varying(35), 
	
	landkreis character varying(11), 
	waldumbau character varying(13), 
	nadelwald character varying(10), 
	landeswald character varying(10), 
	a_qm numeric(20,6), 
	
	moorkorper character varying(10), 
	oezg character varying(10), 
	
	timest_cr timestamp without time zone DEFAULT now(), 
	user_cr character varying(12) DEFAULT "session_user"(), 
	geom geometry (MultiPolygon, 25833), 
	CONSTRAINT fos_moor_pruef_pkey_gid PRIMARY KEY (gid) 
); 

ALTER TABLE fos_moor_pruef OWNER TO adm_forst ; 
--ALTER TABLE fos_moor_pruef OWNER TO ausk_inv ; 
GRANT ALL ON TABLE fos_moor_pruef TO adm_forst ; 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE fos_moor_pruef TO pfl_forst ; 	
GRANT SELECT ON TABLE fos_moor_pruef TO ausk_inv ; 
GRANT SELECT ON TABLE fos_moor_pruef TO ausk_isk ; 

CREATE INDEX fos_moor_pruef_idx_geom ON fos_moor_pruef USING GIST (geom) ; 
CREATE INDEX fos_moor_pruef_idx_nr   ON fos_moor_pruef (nr) ; 

COMMENT ON TABLE fos_moor_pruef IS 'Moorkörper und deren OberflächenEinzugsgebiete [OEzg] ; QuellDaten: xxxxxx'
	COMMENT ON COLUMN fos_moor_pruef.gid IS 'Fortlaufende Identifikationsnummer'	; 
	COMMENT ON COLUMN fos_moor_pruef.nr IS 'Eindeutige Zuordnung der OberflächenEinzugsgebiete [oezg=x] und OEzg-Moor-Paare [JOIN oezg, moorkorper ON nr]'	; 
	COMMENT ON COLUMN fos_moor_pruef.name IS 'Name des Moorkörpers' ; 
	COMMENT ON COLUMN fos_moor_pruef.landkreis IS 'Verortung der Moorkörper/OEzg im Bundesland' ; 
	COMMENT ON COLUMN fos_moor_pruef.a_qm IS 'Flächengröße des Geometrie-Objektes in Quadratmeter' ; 
	COMMENT ON COLUMN fos_moor_pruef.moorkorper IS 'Kennzeichnet Moorkörper-Datensatz falls moorkorper=x' ; 
	COMMENT ON COLUMN fos_moor_pruef.oezg IS 'Kennzeichnet OEzg-Datensatz falls oezg=x' ; 
	COMMENT ON COLUMN fos_moor_pruef.timest_cr IS 'Zeitpunkt der Erstellung des Datensatzes'	; 
	COMMENT ON COLUMN fos_moor_pruef.user_cr IS 'Für die Erstellung des Datensatzes verantwortliche Person' ; 
	COMMENT ON COLUMN fos_moor_pruef.geom IS 'Geometrie-Attribut des Datensatzes' ; 


-------------------------------------------------------------------------------------------------
-- INSERT 		: 		Test-INSERT erfolgreich ? : JA 


INSERT INTO fos_moor_pruef ( nr , name , landkreis , waldumbau , landeswald , nadelwald , a_qm						      , moorkorper , oezg , geom ) 
		    SELECT   nr , name , landkreis , waldumbau , landeswald , nadelwald , TRUNC(ST_Area(moor_oezg_cor.geom)::numeric(20,8),6) , moorkorper , oezg , geom
		    	FROM moor_oezg_cor ; 


-------------------------------------------------------------------------------------------------
-- KONTROLLE 

		SELECT * FROM fos_moor_pruef ; 

	-- Anzahl_Datensätze  
		SELECT (SELECT COUNT(*) FROM moor_oezg_cor) = (SELECT COUNT(*) FROM fos_moor_pruef) ; 	-- 1096 
	-- FlächeSumme  
		SELECT SUM(ST_Area(geom)) FROM moor_oezg_cor ; 		-- 1011331245.6162598 
		SELECT SUM(ST_Area(geom)) FROM fos_moor_pruef ; 	-- 1011331245.6162596		--> Abweichung: 0,2qmm 
				
	--> Geometrie-Prüfung 
		SELECT DISTINCT ST_GeometryType(geom), ST_IsSimple(geom), ST_IsEmpty(geom), ST_IsValid(geom), ST_IsValidReason(geom) 
				FROM fos_moor_pruef ; 				


-------------------------------------------------------------------------------------------------
-- QUELL-TABELLEN_LÖSCHEN ? 

-- 	DROP TABLE IF EXISTS public.fos_moor_pruef  
-- 	DROP TABLE IF EXISTS moor_oezg  
-- 	DROP TABLE IF EXISTS moor_oezg_cor  
