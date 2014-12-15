-----------------------------
--Rémi C
--12/2014
--Thales TTS / IGN Matis-Cogit
---------------------------------------
--projection of points_per_level on a basis of function f_k(i) = (2^k)^i

/*
SET search_path to lod, benchmark_cassette_2013, public;  


SELECT distinct array_length(points_per_level,1) -- gid,  class_ids, class_weight
FROM benchmark_cassette_2013.riegl_pcpatch_space 
		WHERE class_weight IS not null
		AND array_length(class_ids,1)>3



SELECT  gid, points_per_level,  rc_array_padding(points_per_level,2,3)
FROM benchmark_cassette_2013.riegl_pcpatch_space 
	WHERE array_length(points_per_level,1)  =3 
		AND array_length(class_ids,1)>3

SELECT *
FROM benchmark_cassette_2013.riegl_pcpatch_space 
LIMIT 2


*/
 /*
--a plpython function thatdecompose the point per level on a f_k(i) function base, where f_k(i) = (2^k)^i.
DROP FUNCTION IF EXISTS  rc_py_decompose_points_per_level( gid int[], points_per_level int[], start_level int  );
CREATE FUNCTION  rc_py_decompose_points_per_level( gid int[], points_per_level int[], start_level int )
RETURNS  TABLE (gid int, f_1D FLOAT, f_2D FLOAT, f_3D FLOAT)
AS $$  
"""
	@param : gid : list of unique id per points_per_level line
	@param : points_per_level : an array of array. nested array is points_per_level for one patch, completed to fixed size >= end_level
	@param start_level : we will decompose the vector starting from this level
	@param end_level : we stop decomposition on this level
"""
#importing neede modules
import numpy as np ;     
import sys ; 
sys.path.insert(0, '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/script/base_decomp/')

import decomposition_on_dimension_function_base as decomp ;
reload(decomp) ;

#plpy.notice(type(iar));
tmp_result = decomp.decompose_pg(gid , points_per_level,start_level, 3 );
    
result = list()  ; 
#plpy.notice(result)
for i,(l1,l2,l3) in enumerate(tmp_result):  
	result.append( (gid[i] , l1,l2,l3) ) ;   
	
return result  ; 
 
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 


COPY (
WITH patch AS (
	SELECT gid, points_per_level , rc_array_padding(points_per_level,1,3) as ppl_padded
	FROM  benchmark_cassette_2013.riegl_pcpatch_space  
	WHERE points_per_level is not null  
)
,arr_input AS (
	SELECT array_agg(gid order by gid asc) as gids, array_agg_custom(ppl_padded order by gid asc) as ppl_paddeds 
	FROM patch 
) 
SELECT  pc_get((pt).point,'x') as x ,   pc_get((pt).point,'y') as y ,  pc_get((pt).point,'z') as z ,   pc_get((pt).point,'reflectance') as reflectance
		 , r.gid  , r.f_1D   , f_2D  , f_3D
	FROM  arr_input  ,  rc_py_decompose_points_per_level(gids,  ppl_paddeds,1 ) as r   
		NATURAL JOIN riegl_pcpatch_space as rps
		, rc_explodeN_numbered(patch,500) as pt
) TO '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/visu/points_with_dim_LO_2.csv' WITH CSV HEADER; 



 
SELECT rc_array_padding(ARRAY[ 0,1,2,7 ],8,10); 
SELECT array_fill(0, ARRAY[10])

--analysing the repartition of classes

SELECT gid, points_per_level , class_ids, class_weight, unnest(class_ids), unnest(class_weight), numpoints
FROM ( select * , pc_numpoints(patch) as numpoints
FROM  benchmark_cassette_2013.riegl_pcpatch_space 
WHERE array_length(class_ids,1)>3
LIMIT 1) as sb



	--creating function
DROP FUNCTION IF EXISTS rc_points_per_class_computing( class_ids int[], class_weights float[] ) ; 
CREATE OR REPLACE FUNCTION  rc_points_per_class_computing( class_ids int[], class_weights float[] )
RETURNS TABLE( class_id int , class_weight float )
AS $$ 
-- @brief : this function takes input arryas and unnest it. Need this wrapper before 9.4 unnest capability
DECLARE  
BEGIN
	RETURN QUERY 
	SELECT unnest(class_ids), unnest(class_weights) ; 
	
RETURN ; 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT ;


DROP TABLE IF EXISTS class_repartition; 
CREATE TABLE class_repartition AS 
SELECT gid, r.*, pc_numpoints(patch) as npoints 
FROM benchmark_cassette_2013.riegl_pcpatch_space  , rc_points_per_class_computing(class_ids, class_weight) as r 

SELECT *
FROM class_repartition
LIMIT 1 
 ALTER TABLE class_repartition ADD COLUMN points_in_class FLOAT 
 UPDATE class_repartition SET points_in_class = npoints*  class_weight

 DROP TABLE IF EXISTS distinct_class_repartition; 
CREATE TABLE distinct_class_repartition AS 
	SELECT class_id , sum(points_in_class) as point_in_class , count(*) as patch_numbers
	FROM class_repartition
	GROUP BY class_id
	ORDER BY class_id ASC 

DROP TABLE IF EXISTS statisticaly_strong_classes  ;
CREATE TABLE  statisticaly_strong_classes AS 
	SELECT row_number() over(ORDER BY npatch DESC, kpoints DESC, en ) as ngid ,id, en, kpoints, npatch
	FROM  (
		SELECT bc.gid as ngid, bc.id,bc.en, round(sum(dcr.point_in_class)/1000) as kpoints , sum(dcr.patch_numbers  ) as npatch
		FROM distinct_class_repartition  AS dcr
			LEFT OUTER JOIN benchmark_cassette_2013.benchmark_classification as bc ON (bc.id =( dcr.class_id/1000)::int*1000) 
		GROUP BY bc.gid, bc.id , bc.en 
	) as sub
	WHERE npatch >= 100
	ORDER BY npatch DESC, kpoints DESC, en; 

UPDATE statisticaly_strong_classes SET 


SELECT *
FROM statisticaly_strong_classes
302020288 -- 
303030304 --scooter
303040192 --car 

	SELECT *
	FROM benchmark_cassette_2013.benchmark_classification

	SELECT (class_ids[1]/1000)::int * 1000, sum(class_weight[1]*pc_numpoints(patch)) as spoints, count(*), bc.en
	FROM benchmark_cassette_2013.riegl_pcpatch_space
		LEFT OUTER JOIN benchmark_cassette_2013.benchmark_classification as bc ON ( (class_ids[1]/1000)::int*1000 = bc.id)
	GROUP BY (class_ids[1]/1000)::int * 1000,bc.en
	LIMIT 1 
 


COPY ( 
SELECT  pc_get((pt).point,'x') as x ,   pc_get((pt).point,'y') as y ,  pc_get((pt).point,'z') as z ,   pc_get((pt).point,'reflectance') as reflectance
		 , rps.gid   , COALESCE(class,-1), COALESCE(bc.gid ,-1 ) AS new_class_id
	FROM    riegl_pcpatch_space as rps
		, rc_explodeN_numbered(patch,100) as pt
		,pc_get((pt).point,'class') AS class
		 LEFT OUTER JOIN benchmark_cassette_2013.benchmark_classification as bc ON ( (class/1000)::int*1000 = bc.id)
) TO '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/visu/points_with_nclass_id.csv' WITH CSV HEADER; 


--there are error is the stored class.





	--creating function
DROP FUNCTION IF EXISTS rc_class_to_weight_vector( class_ids int[], class_weights float[] ) ; 
CREATE OR REPLACE FUNCTION  rc_class_to_weight_vector( class_ids int[], class_weights float[] , OUT weight_vector float[]) 
AS $$ 
-- @brief : this function transfor detailed class and weight into statistical significant class and weight into a weight per class vector
DECLARE  
BEGIN 
		
		WITH unnested AS (--decompose the arrya into individual classes 
			SELECT (unnest(class_ids)/1000)::int*1000 as id, unnest(class_weights ) as class_weight 
		) --keeping only classes that are significant
		 ,significant_class AS (
			SELECT id, sum(class_weight) as class_weight, first(ngid ) as ngid, first(en) as en, first(kpoints) as kpoints, first(npatch) as npatch
			FROM unnested
				NATURAL JOIN statisticaly_strong_classes as ssc
			WHERE class_weight > 0.01
			GROUP BY id
		) ,
		min_max AS (
			SELECT max(ngid)-min(ngid) +1 AS r
			FROM statisticaly_strong_classes
		),
		creating_vector AS (
			SELECT s.* 
			FROM min_max, generate_series(1,r) as s 
		)
		 ,joining_class AS(  
			SELECT s, COALESCE(class_weight,0)  AS class_weight, sc.en
			FROM creating_vector   as cv
				LEFT OUTER JOIN significant_class as sc ON (cv.s = sc.ngid)
		) ,
		creating_vect AS (
			SELECT array_agg(class_weight ORDER BY s ASC )  as weight_vect
			FROM joining_class
		)
		SELECT weight_vect INTO weight_vector
		FROM creating_vect ;

RETURN ; 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT ;

--test 
	WITH inp AS (
			SELECT class_ids, class_weight 
			FROM benchmark_cassette_2013.riegl_pcpatch_space  
			Where array_length(class_ids ,1) > 3
			LIMIT 100
		) 
	SELECT rc_class_to_weight_vector(class_ids, class_weight) 
	FROM inp ; 


	WITH inp AS (
		SELECT class_ids, class_weight 
		FROM benchmark_cassette_2013.riegl_pcpatch_space  
		Where array_length(class_ids ,1) > 3
		LIMIT 1 
	) 
	,unnested AS (--decompose the arrya into individual classes 
	SELECT (unnest(class_ids)/1000)::int*1000 as id, unnest(class_weight ) as class_weight
	FROM inp
	) --keeping only classes that are significant
	 ,significant_class AS (
		SELECT *
		FROM unnested
			NATURAL JOIN statisticaly_strong_classes as ssc
		WHERE class_weight > 0.01
	) ,
	min_max AS (
		SELECT max(ngid)-min(ngid) +1 AS r
		FROM statisticaly_strong_classes
	),
	creating_vector AS (
		SELECT s.* 
		FROM min_max, generate_series(1,r) as s 
	)
	 ,joining_class AS(  
		SELECT s, COALESCE(class_weight,0)  AS class_weight, sc.en
		FROM creating_vector   as cv
			LEFT OUTER JOIN significant_class as sc ON (cv.s = sc.ngid)
	) ,
	creating_vect AS (
		SELECT array_agg(class_weight ORDER BY s ASC )  as weight_vect
		FROM joining_class
	)
	SELECT *
	FROM creating_vect ;

*/


--a plpython function thatdecompose the point per level on a f_k(i) function base, where f_k(i) = (2^k)^i.
DROP FUNCTION IF EXISTS  rc_py_RForest_regression( gid int[], feature float[], gt_weight_vect float[]);
CREATE FUNCTION  rc_py_RForest_regression( gid int[], feature float[], gt_weight_vect float[] )
RETURNS TABLE(report TEXT) --TABLE (gid int,predicted_wv FLOAT[])
AS $$  
"""
	@param : gid : list of unique id per observation, N size
	@param : feature : an array of N*K features (descriptors)
	@param gt_weight_vect :  the ground trut array, with a given % per class for each observation
	@return  predicted_wv : the result of random forest : a weight predicted per class
"""
#plpy.notice(gid);
#plpy.notice(feature);
#plpy.notice(gt_weight_vect);

#importing needed modules
import numpy as np ;     
import sys ;  
sys.path.insert(0, '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/script/loading benchmark')

import rforest_regressor as reg_rforest; 
reload(reg_rforest) ;
re = reg_rforest.rf_regressor_pg(gid, feature,gt_weight_vect) ; 
plpy.notice(re );

 
result = list()  ; 
#plpy.notice(result)
#for i,(l1,l2,l3) in enumerate(tmp_result):  
#	result.append( (gid[i] , l1,l2,l3) ) ;   
	
return re  ; 
 
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 
 


	WITH inp AS ( --get all interesting observations
		(SELECT gid,  class_ids, class_weight ,points_per_level as ppl , rc_class_to_weight_vector(class_ids, class_weight)  as  r,random() AS rand
 		FROM benchmark_cassette_2013.riegl_pcpatch_space  
 		 WHERE --points_per_level IS NOT NULL AND
			  array_length(class_ids ,1) > 1
 		ORDER BY gid ASC)
		UNION ALL --we are going to normalize the number of obs in each category
		(SELECT gid,  class_ids, class_weight ,points_per_level as ppl , rc_class_to_weight_vector(class_ids, class_weight)  as  r, random() AS rand
		FROM benchmark_cassette_2013.riegl_pcpatch_space  
		WHERE -- points_per_level IS NOT NULL AND
			  array_length(class_ids ,1) = 1
		ORDER BY gid ASC ) 
	) 
	, unnesting_id AS (
		SELECT gid,   (unnest(class_ids)/1000)::int*1000 as sclass_id 
		FROM inp  
	)
	, nobs_of_class as (
		SELECT  sclass_id, count(*) as nobs_of_class 
		FROM unnesting_id  
		GROUP BY sclass_id  
	)
	 ,filtering_ids AS (
		SELECT * 
		FROM nobs_of_class AS si, statisticaly_strong_classes as ssc
			WHERE si.sclass_id = ssc.id
			--additionnal class reduction possible here : 
			--AND ...
	)
	,min_nobs AS (
		SELECT min( nobs_of_class ) AS min_nobs_of_class
		FROM filtering_ids  
		LIMIT 1 
	)
	,unnesting_id_weighted AS (
		SELECT ui.*, min_nobs_of_class / ( fi.nobs_of_class *1.0) as weight
		FROM unnesting_id as ui
			NATURAL JOIN  filtering_ids AS fi  
			,min_nobs 
	)
	,final_weight AS (
		SELECT gid, round(max(weight),5) as weight
		FROM unnesting_id_weighted
		GROUP BY gid
	) 
	 , debiased_observation AS ( 
		SELECT inp.* , fw.weight
		FROM inp 
			NATURAL JOIN final_weight as fw 
			WHERE rand < fw.weight
			--WHERE rand < 2* 100 / (nobs_of_class*1.0) 
			--WHERE rand  < 1000.0/(  nobs_of_class::float)
	)
	,checking_class_repartition AS (
		SELECT  (class_ids[1]/1000)::int*1000,  count(*)
		FROM debiased_observation
		GROUP BY (class_ids[1]/1000)::int*1000
	)
	 , agg AS (
		SELECT array_agg(gid ORDER BY gid ASC) AS gids
			, array_agg_custom(
				ARRAy[	COALESCE(ppl[2],0)
					,COALESCE(ppl[3],0)
					,COALESCE(ppl[4],0)
					]::FLOAT[]
				ORDER BY gid ASC) AS features
			, array_agg_custom(  weight_vector ORDER BY gid ASC) AS weight_vectors
		FROM debiased_observation , rc_class_to_weight_vector(class_ids, class_weight)  as  r
	)
	SELECT r.*
	FROM agg , rc_py_RForest_regression(gids,features, weight_vectors)  AS r  ; 
 


 SELECT avg(
	COALESCE(points_per_level[2],0)) as ppl2
	, avg(COALESCE(points_per_level[3],0)) as ppl3
	, avg(COALESCE(points_per_level[4],0)) as ppl4
	, avg(COALESCE(points_per_level[5],0)) as ppl5
 FROM benchmark_cassette_2013.riegl_pcpatch_space  
 WHERE points_per_level[3] >=45
 LIMIT 10

SELECT points_per_level, dominant_simplified_class,pc_numpoints(patch) 
  FROM benchmark_cassette_2013.riegl_pcpatch_space  
-- WHERE points_per_level[3] >=55 
WHERE (class_ids[1]/1000::int)*1000 = 304020000
 LIMIT 100 

 SELECT *
 FROM lod.statisticaly_strong_classes 

 SELECT count(*)--, pc_numpoints(patch)
 FROM benchmark_cassette_2013.riegl_pcpatch_space  
WHERE dominant_simplified_class is null
AND (points_per_level[1]/1000)::int*1000 = 304020000/1000*1000
LIMIT 100 