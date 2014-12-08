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

#plpy.notice(type(iar));
tmp_result = octree_ordering.order_by_octree_pg(iar, tot_level,stop_level,data_dim);

#plpy.notice(tmp_result);

#result.append(  (cyl_result ) );   
result = list()  ; 
#plpy.notice(result)
for indices,lev in tmp_result:  
	result.append(( (indices) , (lev)  )) ;  
 
return list(result) ; #  #result ; 
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 


 /*
COPY (

	WITH patch AS ( 
		SELECT * , 3 As rounding_digits
		FROM benchmark_cassette_2013.riegl_pcpatch_space 
		WHERE pc_numpoints(patch) BETWEEN 2000 AND 3000
		--AND patch_area > 0.9
		AND gid = 1107
		--LIMIT 1  
	)
	,points AS (
		SELECT 
			round(PC_Get((pt).point,'X'),rounding_digits)  as x
			, round(PC_Get((pt).point,'Y'),rounding_digits) as y 
			, round(PC_Get((pt).point,'Z'),rounding_digits) as  z
			,(pt).ordinality
		FROM patch, rc_explodeN_numbered(patch,-1) as pt  
		) 
	,points_LOD AS (
		SELECT r.level, r.ordering
		FROM (
			SELECT array_agg_custom(
			ARRAY[ x , y , z ] ORDER BY ordinality ASC ) as arr
			FROM points
		) AS pts_arr,rc_py_MidOc_ordering(arr,6,6,3) as  r
		ORDER BY level ASC, ordering ASC
	)
	SELECT points.x, points.y,points.z, row_number() over(order by level ASC NULLS LAST, random())AS nordering ,coalesce(level,-1) as level
	FROM points
		LEFT OUTER JOIN points_LOD  AS plod on (points.ordinality = plod.ordering)
		ORDER BY plod.level NULLS LAST,nordering
)
TO '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/visu/test_octree_python.csv' WITH CSV HEADER; 

*/


--a plpython function taking the array of double precision and converting it to array of points, then computing an ordering of the points following MidOc
DROP FUNCTION IF EXISTS rc_py_MidOc_ordering_patch ( ipatch pcpatch ,int,int,int,int );
CREATE OR REPLACE FUNCTION rc_py_MidOc_ordering_patch (
	ipatch pcpatch 
	,tot_level int DEFAULT 7
	,stop_level int DEFAULT 3
	,data_dim int DEFAULT 3
	,rounding_digits int DEFAULT 3
	,OUT opatch PCPATCH
	, OUT points_per_level INT[]
	)  
AS $$ 
DECLARE
q text;
r record;
BEGIN

q := format('
	WITH  points AS (
		SELECT 
			round(PC_Get((pt).point,''X''),%s)  as x
			, round(PC_Get((pt).point,''Y''),%s) as y 
			, round(PC_Get((pt).point,''Z''),%s) as  z
			,(pt).ordinality
			, pt.point as opoint
		FROM  rc_explodeN_numbered($1,-1) as pt   
		) 
	,points_LOD AS (
		SELECT r.level, r.ordering
		FROM (
			SELECT array_agg_custom(
			ARRAY[ x , y , z ] ORDER BY ordinality ASC ) as arr
			FROM points
		) AS pts_arr,rc_py_MidOc_ordering(pts_arr.arr,%s,%s,%s) as  r  
	), pt_p_l AS( 
		SELECT array_agg(n_per_lev::int oRDER BY level ASC ) as points_per_level
		FROM 
			(SELECT  level, count(*) as n_per_lev
			FROM points_LOD
			GROUP BY level ) as sub
	)
	SELECT   pa.patch  , pt_p_l.points_per_level 
	FROM pt_p_l,
		(  SELECT  pc_patch(points.opoint order by level ASC NULLS LAST, random())  as patch
		FROM points
			LEFT OUTER JOIN points_LOD  AS plod on (points.ordinality = plod.ordering) ) as pa ;
',rounding_digits,rounding_digits,rounding_digits,tot_level ,stop_level ,data_dim  );
		EXECUTE q USING ipatch INTO opatch,points_per_level;
		--opatch:= r[1] ;
		--points_per_level := r[2] ; 
		--opatch, points_per_level ; 
		--raise notice '%',q; 
		 RETURN   ;
	END;
$$ LANGUAGE plpgsql IMMUTABLE CALLED ON NULL INPUT ;
 

COPY ( 
	WITH patch AS ( 
		SELECT r.* , 3 as rounding_digits , pc_numpoints(patch) , pc_numpoints(opatch)
		FROM benchmark_cassette_2013.riegl_pcpatch_space 
			,rc_py_MidOc_ordering_patch(patch,6,6,3,3) as r    
		WHERE pc_numpoints(patch) >=100
		--AND patch_area > 0.9
		AND gid  = 4440 
		--LIMIT 1  
	)  
	SELECT 
		round(PC_Get((pt).point,'X'),rounding_digits)  as x
		, round(PC_Get((pt).point,'Y'),rounding_digits) as y 
		, round(PC_Get((pt).point,'Z'),rounding_digits) as  z
		, round(PC_Get((pt).point,'reflectance'),rounding_digits) as reflectance
		,(pt).ordinality
		,(pt).ordinality
		,(pt).ordinality
	FROM patch, rc_explodeN_numbered( opatch,-1) as pt  
	 
)
TO '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/visu/test_octree_python.csv' WITH CSV HEADER; 


	WITH patch AS ( 
		SELECT * , 3 As rounding_digits, pc_numpoints(patch)
		FROM benchmark_cassette_2013.riegl_pcpatch_space 
		WHERE pc_numpoints(patch) BETWEEN 0 AND 255
		AND patch_area > 0.9
		AND gid  = 4440 
		LIMIT 1  
	)
	SELECT r.*
	FROM patch,rc_py_MidOc_ordering_patch(patch,6,6,3,3) as r  ;

	
 