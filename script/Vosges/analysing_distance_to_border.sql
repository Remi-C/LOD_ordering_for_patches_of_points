--analysing vosges classification result.

--<e have the intuition that the results are majoritary wrong close to groudh truth area border.
--this would point to imprecision in ground truth.

--to test this hypothesys, we compute 
	-- for random observations, the distance to closest border
	-- for wreong observation, the distance to closest border

--create a border table :
SET search_path to vosges_2011, ocs,benchmark_cassette_2013, public;


DROP TABLE IF EXISTS ocs.ocs_border ; 
CREATE TABLE ocs.ocs_border AS 
SELECT row_number() over() as gid, tfv , d.geom
FROM ocs."Export_Foret67" , rc_dumplines(sgeom) as  d
LIMIT 1 
CREATE INDEX ON ocs.ocs_border (gid);
CREATE INDEX ON ocs.ocs_border USING GIST(geom);

SELECT *
FROM ocs."Export_Foret67" 
LIMIT 1 

SELECT count(*)
FROM las_vosges_proxy
WHERE array_length(gt_classes,1)>1

SELECT *
FROM benchmark_cassette_2013.riegl_pcpatch_proxy
LIMIT 1
105041

SELECT min(gid), max(gid)
FROM las_vosges_proxy

SELECT vcp.* , lvp.gid
FROM visu_classif_paris AS vcp   
LEFT OUTER JOIN bench  AS lvp ON vcp.gid = lvp.gid
LIMIT 1

WITH mapping_old_new_class AS (
	SELECT  gt_class, trunc(lvp.class_ids[1]/1000)*1000 as sclass, class_weight, bc.en
	FROM visu_classif_paris AS vcp   
		LEFT OUTER  JOIN riegl_pcpatch_proxy AS lvp ON lvp.gid = vcp.gid
		LEFT OUTER JOIN benchmark_classification AS bc oN (trunc(lvp.class_ids[1]/1000)*1000 =bc.id) 
	
),total_number_per_class AS (
	SELECT gt_class, count(*) count_total
	FROM benchmark_cassette_2013.visu_classif_paris AS vcp   
	GROUP BY gt_class 	 
)
, mixed_number_per_class AS (
	SELECT gt_class, count(*) count_mixed
	FROM benchmark_cassette_2013.visu_classif_paris AS vcp   
		LEFT OUTER  JOIN las_vosges_proxy AS lvp ON lvp.gid = vcp.gid
	WHERE array_length(gt_classes,1)>1 
	GROUP BY gt_class 
	
)
,tot_error AS (
	SELECT gt_class, count(*) count_total
	FROM benchmark_cassette_2013.visu_classif_paris AS vcp   
	WHERE is_correct = false
	GROUP BY gt_class 
)
,mixed_error AS (
	SELECT gt_class, count(*) count_mixed
	FROM benchmark_cassette_2013.visu_classif_paris AS vcp   
		LEFT OUTER  JOIN las_vosges_proxy AS lvp ON lvp.gid = vcp.gid
	WHERE array_length(gt_classes,1)>1 
		AND  is_correct = false
	GROUP BY gt_class 
)
SELECT gt_class, count_total , count_mixed , count_mixed / (count_total*1.0) 
FROM total_number_per_class AS ttpc
	NATURAL  JOIN mixed_number_per_class 
	


SELECT *
FROM benchmark_cassette_2013.statisticaly_strong_classes 
SELECT  gt_class, count(*)  
FROM benchmark_cassette_2013.visu_classif_paris AS vcp   
	LEFT OUTER  JOIN las_vosges_proxy AS lvp ON lvp.gid = vcp.gid
WHERE -- array_length(gt_classes,1)>1 AND
 is_correct = false
 GROUP BY gt_class
visu_classif_vosges


4800/25000
SELECT count(*)/ (SELECT 1.0*count(*) FROM predicted_result_with_ground_truth_50k_3_classes_all_dim)
FROM predicted_result_with_ground_truth_50k_3_classes_all_dim 
WHERE is_correct =true
LIMIT 1 


DROP TABLE IF EXISTS distance_distribution_all ;
CREATE TABLE distance_distribution_all AS 
SELECT distinct on (vcv.gid) vcv.*
FROM visu_classif_vosges as vcv 
	, ocs.ocs_border AS ob
WHERE ST_DWithin(vcv.geom, ob.geom , 5000)
order by vcv.gid, st_distance(vcv.geom, ob.geom) ASC 
LIMIT 100

DROP TABLE IF EXISTS distance_distribution_all ;
CREATE TABLE distance_distribution_all AS  
SELECT distinct on (vcv.gid) vcv.*, st_distance(vcv.geom, ob.geom) as dist
FROM visu_classif_vosges as vcv 
	, ocs.ocs_border AS ob
WHERE ST_DWithin(vcv.geom, ob.geom , 500)
order by vcv.gid, st_distance(vcv.geom, ob.geom) ASC 
LIMIT 100
--99% of observation are less than 500 meters from border. We exploit this fact to 
CREATE INDEX ON distance_distribution_all (is_correct)
CREATE INDEX ON distance_distribution_all (dist)

SELECT avg(dist)
FROM distance_distribution_all
 WHERE is_correct = false 


WITH all_dist AS (
	SELECT array_agg( dist ) as dist_all
	FROM distance_distribution_all
	 WHERE dist < 100
)
, error_dist AS (
	SELECT array_agg( dist ) as dist_error
	FROM distance_distribution_all
	WHERE is_correct = false
	 AND dist < 100
)  
 SELECT r.*
 FROM all_dist,   error_dist
	,rc_py_plot_2_hist(
		dist_all,dist_error
		,'/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/result_rforest/vosges/tmp/test_hist.png'
		,ARRAY['dist_all','dist_error' ]
		,60) as r 
 
--second hypothesys : check how many percent of the wrong prediction are in fact multiclass observation

--get prediction, join to get number of classes
SELECT vcv.* , lvp.fi
FROM visu_classif_vosges as vcv 
	NATURAL JOIN las_vosges_proxy as lvp
LIMIT 100
	SELECT *
	FROM  las_vosges_proxy as lvp
	LIMIT 1 