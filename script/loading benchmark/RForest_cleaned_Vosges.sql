-----------------------------
--Rémi C
--11/2014
--Thales TTS / IGN Matis-Cogit
---------------------------------------
--We try to do best that we can we all ready made simple descriptors
--
SET search_path to vosges_2011, public;

--adding descriptor
	-- height of the patch
	-- height above the laser
	-- area of the patch (2D)
	-- range of reflectance 
	--max(numbe rof echo ) 


/*
ALTER TABLE riegl_pcpatch_space  ADD COLUMN patch_height float; 
ALTER TABLE riegl_pcpatch_space  ADD COLUMN height_above_laser float; 
ALTER TABLE riegl_pcpatch_space  ADD COLUMN patch_area float; 
ALTER TABLE riegl_pcpatch_space  ADD COLUMN reflectance_avg float; 
ALTER TABLE riegl_pcpatch_space  ADD COLUMN nb_of_echo_avg float; 

CREATE INDEX ON riegl_pcpatch_space (patch_height) ;
CREATE INDEX ON riegl_pcpatch_space (height_above_laser) ;  
CREATE INDEX ON riegl_pcpatch_space (patch_area) ;  
CREATE INDEX ON riegl_pcpatch_space (reflectance_avg) ;  
CREATE INDEX ON riegl_pcpatch_space (nb_of_echo_avg) ;  

--filling  :

SELECT COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0) AS patch_height
	,  COALESCE( round(PC_PatchAvg(patch, 'z_origin'),3),0 ) AS height_above_laser
	, COALESCE(round(ST_Area(patch::geometry)::numeric,3),0) AS patch_area
	,  COALESCE( round(PC_PatchAvg(patch, 'reflectance'),3),0 ) AS reflectance_avg
	,  COALESCE( round(PC_PatchAvg(patch, 'nb_of_echo') ,3),0) AS nb_of_echo_avg
FROM riegl_pcpatch_space 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL
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


rc_pcpatch_compute_crude_descriptors(patch ) 

SELECT patch_height,height_above_laser,patch_area,reflectance_avg,nb_of_echo_avg
FROM riegl_pcpatch_space 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
 AND gid <6000
LIMIT  100;


SELECT *
FROM acquisition_tmob_012013.riegl_pcpatch_space  


SELECT rc_pcpatch_real_area_N(patch,85,0.06,0.2)
FROM riegl_pcpatch_space 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
AND gid = 1125;



DROP FUNCTION IF EXISTS rc_pcpatch_real_area_N( ipatch PCPATCH, n_points int, point_size float, reg_size float, OUT approx_area float) ; 
CREATE OR REPLACE FUNCTION rc_pcpatch_real_area_N(ipatch PCPATCH, n_points int DEFAULT 85, point_size float DEFAULT 0.06, reg_size float DEFAULT 0.2, OUT approx_area float)
AS $$ 
-- @brief : this function takes only first points of a patch, then use it to compute an approx area
DECLARE  
BEGIN
	--keep only 3 first digits 
	SELECT ST_Area( 
			ST_Buffer(
				ST_Union(
					ST_Buffer(  (pt).point::geometry   ,reg_size,'quad_segs=2')
				)
			,-(reg_size-point_size)
			) ) into approx_area  
FROM  rc_explodeN_numbered(ipatch,n_points) as pt  ;

RETURN ; 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT ;

DROP FUNCTION IF EXISTS rc_pcpatch_compute_crude_descriptors( ipatch PCPATCH ) ; 
CREATE OR REPLACE FUNCTION rc_pcpatch_compute_crude_descriptors(ipatch PCPATCH ,out  patch_height float, out height_above_laser float, out reflectance_avg float, out nb_of_echo_avg float  )
AS $$ 
-- @brief : this function takes only first points of a patch, then use it to compute an approx area
DECLARE  
BEGIN
	SELECT  COALESCE( round(max(z)-min(z),3),0 )
		,  COALESCE( round(min(z)-avg(z_origin ),3),0 ) 
		,   COALESCE( round(avg(reflectance),3),0 ) 
		,  COALESCE( round(avg(nb_of_echo),3),0 )  into patch_height,height_above_laser,reflectance_avg,nb_of_echo_avg
	FROM 
		 (SELECT 
			(pt).ordinality 
			, COALESCE( round(pc_get((pt).point,'z'),3),0 ) as z
			, COALESCE( round(pc_get((pt).point,'z_origin'),3),0 ) as z_origin 
			, COALESCE( round(pc_get((pt).point,'reflectance'),3),0 ) as  reflectance
			, COALESCE( round(pc_get((pt).point,'nb_of_echo'),3),0 )  as nb_of_echo
		FROM   rc_explodeN_numbered(ipatch,1000) as pt ) AS points ;

RETURN ; 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT ;




	

WITH points AS (
	SELECT 
		(pt).ordinality 
		, COALESCE( round(pc_get((pt).point,'z'),3),0 ) as z
		, COALESCE( round(pc_get((pt).point,'z_origin'),3),0 ) as z_origin 
		, COALESCE( round(pc_get((pt).point,'reflectance'),3),0 ) as  reflectance
		, COALESCE( round(pc_get((pt).point,'nb_of_echo'),3),0 )  as nb_of_echo
	FROM riegl_pcpatch_space , rc_explodeN_numbered(patch,1000) as pt 
	WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
	AND gid = 1125 
)



SELECT  COALESCE( round(max(z)-min(z),3),0 ) AS patch_height
	,  COALESCE( round(min(z)-avg(z_origin ),3),0 ) AS height_above_laser 
	,   COALESCE( round(avg(reflectance),3),0 ) AS reflectance_avg
	,  COALESCE( round(avg(nb_of_echo),3),0 ) AS nb_of_echo_avg
FROM points 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL
LIMIT 1  ; 


SELECT count(*)
FROM riegl_pcpatch_space   
where ( dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL) 

*/


DROP FUNCTION IF EXISTS test_python() ;
create FUNCTION   test_python() 
returns boolean AS
$$
import sklearn;
reload(sklearn)
import pandas
reload(pandas)
from sklearn.preprocessing import StandardScaler
return True; 
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 
SELECT *
FROM test_python() ; 


	--a plpython predicting gt_class, cross_validation , result per class 
	--gids,feature_iar,gt_classes    ,labels,class_list,k_folds,random_forest_ntree, plot_directory
DROP FUNCTION IF EXISTS rc_random_forest_train_predict( gids int[], feature_iar FLOAT[], gt_classes int[]
	, class_list int[], labels text[], k_folds int , random_forest_ntree int , plot_directory text );
CREATE FUNCTION rc_random_forest_train_predict( gids int[], feature_iar FLOAT[], gt_classes int[]
	, class_list int[], labels text[], k_folds int , random_forest_ntree int , plot_directory text )
RETURNS TABLE(gid int, gt_class INT, prediction INT, confidence FLOAT )--TABLE (gid int, predicted_class int, confidence float)
AS $$"""
This function use random forest on an input vector to learn with k-1/k of the vector and  predict on k.
It returns the prediction
""" 
import sys
sys.path.insert(0, '/media/dca349df-2074-430b-b9b8-a4cc4684975b/test_pg_lidar/LOD')
plpy.notice(labels)
import matplotlib 
matplotlib.use('Agg')
import Rforest_on_patch;
reload(Rforest_on_patch)
import numpy as np

#constructing input of the python function
result = Rforest_on_patch.RForest_learn_predict_pg(gids,feature_iar,gt_classes,labels, k_folds,random_forest_ntree, plot_directory) ; 


#returning: 
re = np.column_stack((result['gid'],result['ground_truth_class'].astype(int), result['class_chosen'].astype(int), result['proba_chosen']  )) ;
#plpy.notice(re);
to_be_returned = [] ;
for a in re:
	to_be_returned.append(   ( int(a[0]),  int(a[1]), int(a[2]), float(a[3]) ) );

return to_be_returned ;
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 
 
 



	WITH patch_to_use AS (
			 SELECT  gid , 	substring(gt_classes[1] from 1 for 3) as sgt_class, gt_weight[1], avg_intensity, avg_tot_return_number, avg_z, avg_height 
				,points_per_level
				,random() as rand
			 FROM las_vosges_proxy     
			WHERE  gt_weight[1] > 0.9
				AND points_per_level IS NOT NULL
			LIMIT 1000
	)
	,count_per_class as (
		SELECT sgt_class, row_number() over(ORDER BY sgt_class ASC) AS n_class_id , count(*) AS  obs_per_class
		FROM  patch_to_use 
		GROUP BY sgt_class	
	) 
	, array_agg AS (
		SELECT array_agg(gid ORDER BY gid ASC) AS gids
			,array_agg_custom( 
				ARRAY[points_per_level[2],points_per_level[3],points_per_level[4],points_per_level[5], gt_weight,avg_intensity, avg_tot_return_number, avg_z, avg_height ] 
				ORDER BY gid ASC ) AS feature_arr 
			, array_agg(    cc.n_class_id::int  ORDER BY gid ASC) as gt_class
		FROM patch_to_use
			LEFT OUTER JOIN count_per_class AS cc ON (cc.sgt_class =  patch_to_use.sgt_class)
	)
	--,result_classif AS (
		SELECT  r.gid, r.gt_class, r.prediction, r.confidence 
		FROM array_agg
			,rc_random_forest_train_predict(
				gids
				,feature_arr
				,gt_class
				, (SELECT array_agg(n_class_id::int ORDER BY n_class_id ) AS n_class_id FROM count_per_class)
				,  (SELECT array_agg(sgt_class ORDER BY n_class_id ) AS sgt_class FROM count_per_class)
				,  10
				, 10
				, '' ) as r   
	
/*
SELECT count(*)
FROM benchmark_cassette_2013.riegl_pcpatch_space 
WHERE pc_numpoints(patch)>100

COPY (
WITH patch_to_use AS (
			 SELECT gid ,'bench' AS src  ,points_per_level 
				, 	dominant_simplified_class  
					--CASE WHEN  dominant_simplified_class !=2 THEN 0 ELSE  dominant_simplified_class END
				, patch_height,height_above_laser,patch_area,reflectance_avg,nb_of_echo_avg
				,proba_occurency 
				,random() as rand
			 FROM benchmark_cassette_2013.riegl_pcpatch_space 
			WHERE points_per_level IS NOT NULL
				AND dominant_simplified_class IS NOT NULL 
			 UNION ALL
			 SELECT gid  ,'tmob' AS src ,points_per_level 
				, 	dominant_simplified_class  
					--CASE WHEN  dominant_simplified_class !=2 THEN 0 ELSE  dominant_simplified_class END
				,patch_height,height_above_laser,patch_area,reflectance_avg,nb_of_echo_avg
				,proba_occurency 
				,random() as rand
			 FROM acquisition_tmob_012013.riegl_pcpatch_space 
			 WHERE points_per_level IS NOT NULL  
				AND dominant_simplified_class IS NOT NULL
	)
	,count_per_class as (
		SELECT dominant_simplified_class , count(*) AS  obs_per_class
		FROM  patch_to_use 
		GROUP BY dominant_simplified_class	
	) 
	--,array_agg AS (
		SELECT 
			array_agg(row_number() over(order by gid, src) ORDER BY gid ASC) AS gid
			,   array_agg(     COALESCE(points_per_level[2]/8.0,0)   ORDER BY gid ASC) as f1
			, array_agg(   COALESCE(points_per_level[3]/64.0,0)    ORDER BY gid ASC) as f2 
			, array_agg(  COALESCE(points_per_level[4]/512.0,0)    ORDER BY gid ASC) as f3
			,  array_agg(  COALESCE(points_per_level[5]/4096.0,0)    ORDER BY gid ASC) as f4
			,  array_agg(     COALESCE(patch_height)   ORDER BY gid ASC) as f5
			, array_agg(   COALESCE(height_above_laser)    ORDER BY gid ASC) as f6
			, array_agg(  COALESCE(patch_area)    ORDER BY gid ASC) as f7
			,  array_agg(  COALESCE(reflectance_avg)    ORDER BY gid ASC) as f8
			,  array_agg(  COALESCE(nb_of_echo_avg)    ORDER BY gid ASC) as f9 
			, array_agg(  
				ptu.dominant_simplified_class 
				--CASE WHEN ptu.dominant_simplified_class !=5 THEN 0 ELSE ptu.dominant_simplified_class END
				ORDER BY gid ASC) as gt_class
			,  array_agg(proba_occurency ORDER BY gid ASC) AS proba 
		FROM patch_to_use AS ptu LEFT OUTER JOIN count_per_class AS cpc ON (cpc.dominant_simplified_class = ptu.dominant_simplified_class)
			WHERE  
				 NOT (ptu.dominant_simplified_class = ANY (ARRAY[0, 1]))
				AND rand  < 1000.0/(  obs_per_class::float) --this allows to have approx 1000 obs per class 
				--AND proba_occurency >0.95 
	) 
	,result_classif AS (
		SELECT  r.gid, r.gt_class, r.prediction, r.confidence 
		FROM array_agg,rc_random_forest_cross_valid_per_class_all_features(gid,f1,f2,f3,f4,f5,f6,f7,f8,f9,gt_class,proba,10,30) as r 
	)
	SELECT
		 pc_get((pt).point,'x') AS x
		, pc_get((pt).point,'y') AS y
		, pc_get((pt).point,'z') AS z
		, pc_get((pt).point,'reflectance') AS reflectance
		, (pt).ordinality
		,rc.*
		,((rc.gt_class-rc.prediction)=0)::boolean::int AS is_correct 
		, COALESCE(points_per_level[2]/8.0,0)    as l1
			,  COALESCE(points_per_level[3]/64.0,0)   as l2
			, COALESCE(points_per_level[4]/512.0,0)   as l3
			,  COALESCE(points_per_level[5]/4096.0,0)  as l4
			,  COALESCE(patch_height)   as patch_height
			,  COALESCE(height_above_laser)   as height_above_laser
			, COALESCE(patch_area)  as patch_area
			,   COALESCE(reflectance_avg)  as reflectance_avg
			,   COALESCE(nb_of_echo_avg)  AS nb_of_echo_avg
			
	FROM result_classif as rc
		NATURAL JOIN benchmark_cassette_2013.riegl_pcpatch_space  AS rps  
		,rc_explodeN_numbered(patch, 2000) AS pt

)
TO '/media/sf_perso_PROJETS/lod/patch_with_classif_1000.csv' WITH CSV HEADER
*/