-----------------------------
--Rémi C
--11/2014
--Thales TTS / IGN Matis-Cogit
---------------------------------------
--Pyhton way to compute MidOc

SET search_path to lod,benchmark_cassette_2013, public; 

 
	--a plpython function taking the array of double precision and converting it to array of points, then computing an ordering of the points following MidOc
DROP FUNCTION IF EXISTS rc_py_MidOc_ordering ( FLOAT[] ,int,int,int);
CREATE FUNCTION rc_py_MidOc_ordering (
	iar FLOAT[] 
	,tot_level int DEFAULT 7
	,stop_level int DEFAULT 3
	,data_dim int DEFAULT 3
	) 
RETURNS TABLE( ordering int , level int )   
AS $$
"""  Take a point cloud , and return the MidOc ordering for at least some of the points
""" 
import sys
sys.path.insert(0, '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/script')

import octree_ordering ;
reload(octree_ordering) ;

#plpy.notice(iar);
tmp_result = octree_ordering.order_by_octree_pg(iar, tot_level,stop_level,data_dim);

#plpy.notice(tmp_result);

#result.append(  (cyl_result ) );   
result = list()  ; 
#plpy.notice(result)
for indices,lev in tmp_result:  
	result.append(( (indices) , (lev)  )) ;  
 
return list(result) ; #  #result ; 
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 

COPY (

WITH patch AS ( 
	SELECT * , 3 As rounding_digits
	FROM benchmark_cassette_2013.riegl_pcpatch_space 
	WHERE pc_numpoints(patch) BETWEEN 2000 AND 3000
	AND patch_area > 0.9
	AND gid = 1107
	LIMIT 1  
)
,points AS (
	SELECT 
		round(PC_Get(pt,'X'),rounding_digits)  -2000 as x
		, round(PC_Get(pt,'Y'),rounding_digits) - 20000 as y 
		, round(PC_Get(pt,'Z'),rounding_digits) as  z
		,row_number() over(order by random()) as ordinality
	FROM patch, pc_explode(patch) as pt  
	--LIMIT 200
	)
,pts_arr AS (
	SELECT array_agg_custom(
		ARRAY[
			x
			, y
			, z
		] ORDER BY ordinality ASC ) as arr
	FROM points
)
,points_LOD AS (
	SELECT r.level, r.ordering
	FROM pts_arr,rc_py_MidOc_ordering(arr,7,4,3) as  r
	ORDER BY level ASC, ordering ASC
)
SELECT points.*, row_number() over(order by level ASC NULLS LAST, random())AS nordering ,coalesce(level,-1) as level
FROM points
	LEFT OUTER JOIN points_LOD  AS plod on (points.ordinality = plod.ordering)
	ORDER BY plod.level NULLS LAST,nordering
)
TO '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/visu/test_octree_python.csv' WITH CSV HEADER