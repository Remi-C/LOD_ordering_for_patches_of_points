SET search_path to lod,benchmark_cassette_2013, public; 




SELECT max(c), min(c)
FROM benchmark_cassette_2013.riegl_pcpatch_space,ST_Y(St_Centroid(patch::geometry)) as c
WHERE pc_numpoints(patch) >=1000


COPY ( 
	WITH output_settings AS (
		SELECT 21122 AS y_min,
			40 AS y_length
			,1000 as max_num_points
	) 
		SELECT round(PC_Get((pt).point,'X'),3)  as x
			, round(PC_Get((pt).point,'Y'),3) as y 
			, round(PC_Get((pt).point,'Z'),3) as  z
			, round(PC_Get((pt).point,'reflectance'),3) as reflectance
			,(pt).ordinality 
			,gid
			, CASE WHEN (pt).ordinality  = points_per_level[1] THEN 0 
				WHEN (pt).ordinality > rc_ArraySum(points_per_level,1) AND (pt).ordinality <= rc_ArraySum(points_per_level,2) THEN 1 
				WHEN (pt).ordinality > rc_ArraySum(points_per_level,2) AND (pt).ordinality <= rc_ArraySum(points_per_level,3) THEN 2 
				WHEN (pt).ordinality > rc_ArraySum(points_per_level,3) AND (pt).ordinality <= rc_ArraySum(points_per_level,4) THEN 3
				WHEN (pt).ordinality > rc_ArraySum(points_per_level,4) AND (pt).ordinality <= rc_ArraySum(points_per_level,5) THEN 4
				ELSE -1 END    AS level
				--,r.points_per_level
		FROM output_settings,benchmark_cassette_2013.riegl_pcpatch_space, ST_Y(St_Centroid(patch::geometry))  as c 
			, rc_explodeN_numbered(  patch,(max_num_points* pow((c-y_min)/y_length,3) )::int) as pt  
				WHERE pc_numpoints(patch) >=50
					AND c BETWEEN y_min AND y_min  + y_length 
					AND pc_numpoints(patch) <= max_num_points* pow((c-y_min)/y_length,3)
					AND (pt).ordinality  <= max_num_points* pow((c-y_min)/y_length,3) 
		--AND patch_area > 0.9
		--AND gid  = 4440 
		--LIMIT 1    
)
TO '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/visu/LOD_continuous_LOD.csv' WITH CSV HEADER; 
