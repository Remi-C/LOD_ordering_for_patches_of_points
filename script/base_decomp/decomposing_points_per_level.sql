-----------------------------
--Rémi C
--12/2014
--Thales TTS / IGN Matis-Cogit
---------------------------------------
--projection of points_per_level on a basis of function f_k(i) = (2^k)^i


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



 
--a plpython function thatdecompose the point per level on a f_k(i) function base, where f_k(i) = (2^k)^i.
DROP FUNCTION IF EXISTS  rc_py_decompose_points_per_level( gid int[], points_per_level int[], start_level int );
CREATE FUNCTION  rc_py_decompose_points_per_level( gid int[], points_per_level int[], start_level int )
RETURNS boolean--TABLE (gid int, predicted_class int, confidence float)
AS $$
"""
	@param : gid : list of unique id per points_per_level line
	@param : points_per_level : an array of array. nested array is points_per_level for one patch, completed to fixed size >= end_level
	@param start_level : we will decompose the vector starting from this level
	@param end_level : we stop decomposition on this level
"""
#importing neede modules
import numpy as np ;    

#create numpy array from input vectors
gid_arr  = np.array(gid,dtype=int);
ppl_arr =  np.reshape(np.array(points_per_level), (-1, len(points_per_level)/len(gid_arr)) ) ; 
 
plpy.notice(gid_arr);
plpy.notice(ppl_arr); 

return 1 ; 
 
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 

WITH patch AS (
	SELECT gid, points_per_level , rc_array_padding(points_per_level,2,3) as ppl_padded
	FROM  benchmark_cassette_2013.riegl_pcpatch_space 
	LIMIT 5
)
,arr_input AS (
	SELECT array_agg(gid order by gid asc) as gids, array_agg_custom(ppl_padded order by gid asc) as ppl_paddeds 
	FROM patch 
)
SELECT  r.* 
FROM  arr_input  , 
	rc_py_decompose_points_per_level(gids,  ppl_paddeds, 2) as r 
 


SELECT ARRAY[1,2,4,8] * 3

 
 
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

	SELECT class_id, bc.*, round(dcr.point_in_class/1000) , dcr.patch_numbers  
	FROM distinct_class_repartition  AS dcr
		LEFT OUTER JOIN benchmark_cassette_2013.benchmark_classification as bc ON (bc.id =( dcr.class_id/100)::int*100) 
	WHERE patch_numbers >= 30; 
302020288 -- 
303030304 --scooter
303040192 --car 

	SELECT *
	FROM benchmark_cassette_2013.benchmark_classification