-----------------------------
--Rémi C
--11/2014
--Thales TTS / IGN Matis-Cogit
---------------------------------------
--Pyhton way to compute MidOc

SET search_path to lod,benchmark_cassette_2013, public; 

 
	--a plpython function taking the array of double precision and converting it to array of points, then computing an ordering of the points following MidOc
DROP FUNCTION IF EXISTS rc_py_MidOc_ordering ( FLOAT[] ,int,int);
CREATE FUNCTION rc_py_MidOc_ordering (
	iar FLOAT[] 
	,tot_level int DEFAULT 7
	,data_dim int DEFAULT 3
	) 
RETURNS TABLE( ordering int[], level int[])   
AS $$
"""  Take a point cloud , and return the MidOc ordering for at least some of the points
""" 
import sys
sys.path.insert(0, '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/script')

import octree_ordering ;
reload(octree_ordering) ;
#result.append(  (cyl_result ) );   

#for indices,model, model_type in cyl_result:
#     if model != False:
#	result.append(( (indices),model,model_type ) ) ;  

return result ; 
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 


WITH patch AS ( 
	SELECT *
	FROM benchmark_cassette_2013.riegl_pcpatch_space 
	WHERE pc_numpoints(patch) BETWEEN 1010 AND 2000
	LIMIT 1 
)
,pts_arr AS (
	SELECT  rc_patch_to_XYZ_array( patch,-1 )  as arr
	FROM patch 
)
SELECT rc_py_MidOc_ordering(arr,2,3)
FROM pts_arr;
