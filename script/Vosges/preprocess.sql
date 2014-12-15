-------------------
-- Remi Cura
--IGN
--
--working on Vosges dataset

--removing the trailing part of filename
--was : '../../../data/000004.las' will be '000004.las'

SET search_path to vosges_2011, public ; 

--dealing wit bad file names :

	--what kind of filename do we have?
	SELECT distinct file_name 
	FROM vosges_2011.las_vosges   ; --should be 1456 

	--update data : 
	--UPDATE las_vosges SET file_name = substring(file_name,'.*/data/([0-9]+\.las)')  ; 

	--cheking : 
	SELECT distinct file_name,  substring(file_name,'.*/data/([0-9]+\.las)') 
	FROM vosges_2011.las_vosges   ; --should be 1456 

--
--creating a proxy table, all relevant patch information will be stored here

 
	CREATE TABLE vosges_2011.las_vosges_proxy (
		gid  INT REFERENCES vosges_2011.las_vosges (gid)
		,file_name text 
		,geom GEOMETRY(polygon,931008)
		,num_points int
		,points_per_level int[]
		,gt_classes text[]
		,gt_weight float[]
		,gt_src INT[]
		,avg_height FLOAT 
		,avg_intensity float
		,avg_tot_return_number float
		,avg_Z float
	)
--ALTER TABLE las_vosges_proxy ADD COLUMN gt_src INT[]  
	--creating indexes
	CREATE INDEX ON las_vosges_proxy (gid);
	CREATE INDEX ON las_vosges_proxy (file_name);
	CREATE INDEX ON las_vosges_proxy USING GIST (geom); 
	CREATE INDEX ON las_vosges_proxy (num_points);
	CREATE INDEX ON las_vosges_proxy (points_per_level);
	CREATE INDEX ON las_vosges_proxy (gt_classes);
	CREATE INDEX ON las_vosges_proxy (gt_weight);
	CREATE INDEX ON las_vosges_proxy (avg_intensity);
	CREATE INDEX ON las_vosges_proxy (avg_tot_return_number);
	CREATE INDEX ON las_vosges_proxy (avg_Z);
	CREATE INDEX ON las_vosges_proxy (gt_src);
 
--some info about patches : about 8k points , 50 meter cube
--launching python script to batch compute 
	
	INSERT INTO las_vosges_proxy SELECT gid FROM las_vosges 

--computing indicators :

UPDATE las_vosges_proxy SET (avg_height, avg_Z,avg_intensity, avg_tot_return_number) = 
	(patch_height,z_avg,intensity_avg,tot_return_number_avg )
	FROM (
		SELECT gid,COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0) AS patch_height  
		,COALESCE( round(PC_PatchAvg(patch, 'Z'),3),0 ) AS z_avg
		,  COALESCE( round(PC_PatchAvg(patch, 'intensity'),3),0 ) AS intensity_avg
		,  COALESCE( round(PC_PatchAvg(patch, 'tot_return_number') ,3),0) AS tot_return_number_avg
	FROM las_vosges 
	WHERE gid = 10000
	) AS sub
	WHERE  sub.gid = las_vosges_proxy.gid
	
SELECT COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0) AS patch_height  
	,COALESCE( round(PC_PatchAvg(patch, 'Z'),3),0 ) AS z_avg
	,  COALESCE( round(PC_PatchAvg(patch, 'intensity'),3),0 ) AS intensity_avg
	,  COALESCE( round(PC_PatchAvg(patch, 'return_number') ,3),0) AS tot_return_number_avg
FROM las_vosges 
--WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL
LIMIT 1  ; 


UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET  (patch_height,height_above_laser,patch_area,reflectance_avg,nb_of_echo_avg) = 
	(COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0)  
	,  COALESCE( round(PC_PatchMin(patch, 'Z')-PC_PatchAvg(patch, 'z_origin') ,3),0 )  
	, COALESCE(round(rc_pcpatch_real_area_N(patch,85,0.06,0.2)::numeric,3),0)  
	,  COALESCE( round(PC_PatchAvg(patch, 'reflectance'),3),0 ) 
	,  COALESCE( round(PC_PatchAvg(patch, 'nb_of_echo') ,3),0)   ) 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
AND gid =1125;

UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET  (patch_height ,height_above_laser, reflectance_avg,nb_of_echo_avg) = 
	(ROW(rc_pcpatch_compute_crude_descriptors(patch ))   )
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
AND gid =1125;
 

create table proxy_visu_geom as 
SELECT gid, patch::geometry as geom
FROM  vosges_2011.las_vosges
WHERE gid%10=1 ; 

create index on proxy_visu_geom (gid);
create index on proxy_visu_geom using gist(geom);

--getting ground truth on land use 
SELect *
from ocs."Export_Foret67"
limit 1

--insert into ocs."Export_Foret67" (geom, fid_,tfv,shape_leng,shape_area)
--SELECT geom, fid_,tfv,shape_leng,shape_area
--FROM  ocs."Export_Foret68"

ALTER TABLE ocs."Export_Foret67"  ALTER COLUMN geom  TYPE  geometry(Polygon,931008) USING ST_SetSRID(geom,931008)
 
CREaTE INDEX ON ocs."Export_Foret67" (fid_) 
CREaTE INDEX ON ocs."Export_Foret67" (tfv) ;
CREaTE INDEX ON ocs."Export_Foret67" (shape_leng);
CREaTE INDEX ON ocs."Export_Foret67" (shape_area);


--for each patch, get the class of the closest land cover use, order by shared area, 


SELECT *
FROM las_vosges_proxy LIMIT  1


SELECT p.gid AS patch_id , ocs.gid AS ocs_gid, ocs.tfv
from vosges_2011.las_vosges as p
	INNER JOIN  ocs."Export_Foret67" as ocs ON (ST_Intersects(ocs.geom,p.patch::geometry)=TRUE ) 
--ORDER BY p.gid, ST_Distance(ocs.geom,p.patch::geometry) ASC, shape_area DESC, shape_leng DESC , tfv DESC 
LIMIT 2




