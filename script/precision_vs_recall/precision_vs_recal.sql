

SET search_path to benchmark_cassette_2013, vosges_2011, public;


DROP TABLE IF EXISTS visu_car_qgis_gt ;
CREATE TABLE visu_car_qgis_gt AS  
	SELECT pr.*  ,    bc2.en
	FROM benchmark_cassette_2013.riegl_pcpatch_proxy as pr
		LEFT OUTER JOIN benchmark_cassette_2013.benchmark_classification   as bc2 ON ( trunc(class_ids[1]/100)*100 = bc2.id) 
	WHERE bc2.en =  'other 4+ wheels' 


SELECT en,*
FROM visu_car_qgis_precision
	
SELECT  *
FROM data_plus_class  
WHERE en = 'other 4+ wheels'

DROP TABLE IF EXISTS visu_car_qgis_precision ;
CREATE TABLE visu_car_qgis_precision AS 
WITH data_plus_class AS (
	SELECT pr.*  , bc.geom,  bc2.en
	FROM predicted_result_with_ground_truth_paris AS pr
		LEFT OUTER JOIN benchmark_cassette_2013.riegl_pcpatch_proxy   as bc ON (pr.gid  = bc.gid)
		LEFT OUTER JOIN benchmark_cassette_2013.benchmark_classification   as bc2 ON ( trunc(class_ids[1]/100)*100 = bc2.id) 
	WHERE prediction=20
		--AND gt_class=  20
		AND confidence > 0.1
)
SELECT  *
FROM data_plus_class  
WHERE en = 'other 4+ wheels';
CREATE INDEX ON visu_car_qgis_precision USING GIST(geom)


SELECT en , count(*)
FROM benchmark_cassette_2013.riegl_pcpatch_proxy  
	LEFT OUTER JOIN benchmark_cassette_2013.benchmark_classification   as bc2 ON ( trunc(class_ids[1]/1000)*1000  = bc2.id) 
GROUP  BY en
LIMIT  1

--dilate regular result
visu_car_qgis_recall


SELECT *
FROM benchmark_cassette_2013.riegl_pcpatch_proxy  as rpp
	INNER JOIN visu_car_qgis_precision AS vc ON (ST_DWithin(rpp.geom,vc.geom,5)=TRUE)


SELECT *
FROM benchmark_cassette_2013.benchmark_classification 

	
DROP TABLE IF EXISTS visu_ground_qgis_gt ;
CREATE TABLE visu_ground_qgis_gt AS  
	SELECT pr.* ,    bc2.en
	FROM benchmark_cassette_2013.riegl_pcpatch_proxy as pr
		LEFT OUTER JOIN benchmark_cassette_2013.benchmark_classification   as bc2 ON ( trunc(class_ids[1]/100000)*100000 = bc2.id) 
		,def_zone_article_recall_boost as dzt
	WHERE bc2.en =  'ground' 
	 AND ST_Intersects(dzt.geom, pr.geom) = TRUE;


DROP TABLE IF EXISTS visu_ground_qgis_result ;
CREATE TABLE visu_ground_qgis_result AS  
	SELECT pr.*  
	FROM predicted_result_with_ground_truth_paris AS pr 
	WHERE   gt_class = 2


--select all from ground truth, get those missing with attribute
SELECT *
FROM visu_ground_qgis_gt
	LEFT OUTER JOIN 

DROP TABLE IF EXISTS visu_ground_qgis_recall ;
CREATE TABLE visu_ground_qgis_recall AS  
	SELECT  pr.*
	FROM predicted_result_with_ground_truth_paris AS pr1 
		LEFT OUTER JOIN benchmark_cassette_2013.riegl_pcpatch_proxy as pr ON (pr1.gid = pr.gid )
		,def_zone_article_recall_boost as dzt
	WHERE prediction=2 
	AND ST_Intersects(dzt.geom, pr.geom) = TRUE;
		--AND gt_class=  20
		--AND confidence > 0.1
CREATE INDEX ON visu_ground_qgis_recall USING GIST(geom); 


DROP TABLE IF EXISTS visu_ground_all_together;
CREATE TABLE visu_ground_all_together AS 
SELECT COALESCE(vgt.gid, vgr.gid) AS gid
	, coalesce(vgt.geom, vgr.geom) as geom
	, case when vgt.gid IS NULL then 'extra'  when  vgr.gid IS NULL then 'missing' else 'regular' end as  missing_positiv
FROM visu_ground_qgis_gt as vgt
	FULL OUTER JOIN visu_ground_qgis_recall as vgr ON (vgt.gid = vgr.gid)
	,def_zone_article_recall_boost as dzt
	WHERE ST_Intersects(dzt.geom, COALESCE(vgt.geom,vgr.geom) )= TRUE;


DROP TABLE IF EXISTS visu_ground_qgis_recall_buffered ;
CREATE TABLE visu_ground_qgis_recall_buffered AS  
	SELECT  DISTINCT ON (pr.gid) pr.*
	FROM benchmark_cassette_2013.riegl_pcpatch_proxy as pr
		INNER JOIN visu_ground_qgis_recall as vg ON ( (ST_DWithin(pr.geom, vg.geom, 2 )=TRUE AND abs(vg.height_above_laser-pr.height_above_laser)<=0.50 ) ) 
 
DROP TABLE IF EXISTS visu_ground_all_together_with_buffer;
CREATE TABLE visu_ground_all_together_with_buffer AS 
SELECT COALESCE(vgt.gid, vgr.gid) AS gid
	, coalesce(vgt.geom, vgr.geom) as geom
	, case when vgt.gid IS NULL then 'extra'  when  vgr.gid IS NULL then 'missing' else 'regular' end as  missing_positiv
FROM visu_ground_qgis_gt as vgt
	FULL OUTER JOIN visu_ground_qgis_recall_buffered as vgr ON (vgt.gid = vgr.gid)
	,def_zone_article_recall_boost as dzt
WHERE ST_Intersects(dzt.geom, COALESCE(vgt.geom,vgr.geom) )= TRUE;


CREATE TABLE def_zone_article_recall_boost (
gid serial
,geom geometry(polygon, 932011)  --"POLYGON((1949 21212,1949 21254,1889 21254,1889 21213,1949 21212))"
)  


--getting some stats :

--total patches in the scene :
	SELECT count(*) --3086
	FROM riegl_pcpatch_proxy as vgt
		,def_zone_article_recall_boost as dzt
WHERE ST_Intersects(dzt.geom, vgt.geom) = TRUE;

--missing patches with regular classification, extra patches with regular classification
	SELECT count(*)
	FROM visu_ground_all_together
	WHERE missing_positiv = 'extra' --'missing'

	SELECT count(*)
	FROM visu_ground_all_together_with_buffer
	WHERE missing_positiv = 'extra' --'missing'


--computing the recall for regular case :
SELECT 
	(SELECT count(*)
	FROM visu_ground_all_together 
	WHERE missing_positiv = --'missing' 
		'regular'
	SELECT  407 /439.0 AS recall --0.92710706150341685649
	--total in the zone from ground truth: 439
	--total found in the zone : 
	--classical recall : 92%
	--recall after buffering  : 