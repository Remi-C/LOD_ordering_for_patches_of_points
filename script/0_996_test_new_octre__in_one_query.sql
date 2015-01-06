SELECT gid,PC_NumPoints(patch)
FROM acquisition_tmob_012013.riegl_pcpatch_space as p  --, pc_explode(patch) as pt 
WHERE p.gid BETWEEN 300000 AND 400000 --= 405028 ;
	AND PC_NumPoints(patch) BETWEEN 100 AND 10000
ORDER BY gid ASC
	LIMIT 100


SELECT pc_get(pt.point,'x')AS x, pc_get(pt.point,'y') as y, pc_get(pt.point,'z') as z,  pt.ordinality
FROM acquisition_tmob_012013.riegl_pcpatch_space as p1 ,rc_order_octree(patch,7)  AS r, rc_explodeN_numbered(r.opatch) as pt 
WHERE p1.gid = 3158
		300008		
  -- SET search_path to lod, public ;

  WITH area AS (
	  SELECT ST_Centroid(patch::geometry) as geom
	FROM acquisition_tmob_012013.riegl_pcpatch_space as p1 
	WHERE p1.gid = 300354
	LIMIT 1 
  )
  SELECT  pc_get(pt.point,'x')AS x, pc_get(pt.point,'y') as y, pc_get(pt.point,'z') as z,  pt.ordinality
	FROM area, acquisition_tmob_012013.riegl_pcpatch_space as p-- ,rc_order_octree(patch,7)  AS r, rc_explodeN_numbered(r.opatch) as pt 
	WHERE ST_DWithin(p.patch::geometry, area.geom, 4) = TRUE


--SELECT pg_stat_reset();

SELECT funcname,calls, total_time/1000.0 AS total_time, self_time/1000.0 AS self_time, sum(self_time/1000.0) OVER (order by self_time DESC) As cum_self_time
FROM pg_stat_user_functions
ORDER BY  -- total_time DESC  ,
	self_time DESC; 

COPY  (  
	 
		  WITH area AS (
		  SELECT ST_Centroid(patch::geometry) as geom
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p1 
		WHERE p1.gid = 300354
		LIMIT 1 
		  )
		  SELECT  pc_get(pt.point,'x')AS x, pc_get(pt.point,'y') as y, pc_get(pt.point,'z') as z,  pc_get(pt.point,'reflectance') as reflectance,   pt.ordinality , gid
			FROM area, acquisition_tmob_012013.riegl_pcpatch_space as p, rc_order_octree(patch,7)  AS r, rc_explodeN_numbered(r.opatch) as pt 
			WHERE ST_DWithin(p.patch::geometry, area.geom, 5) = TRUE
					  
		)TO '/media/sf_E_RemiCura/DATA/test_order_octree_patch_around_300354_level_all.csv'-- '/tmp/temp_pointcloud_lod.csv'
WITH csv header;
--3357 sec for 4,9 million points
--1460 pts/sec 


SELECT gid,  points_per_level 
FROM  acquisition_tmob_012013.riegl_pcpatch_space as p
WHERE gid BETWEEN 310000 AND 311000 
AND PC_NumPoints(patch) > 100


UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET points_per_level = NULL; 

COPY  (   
		  SELECT  pc_get(pt.point,'x')AS x, pc_get(pt.point,'y') as y, pc_get(pt.point,'z') as z,  pc_get(pt.point,'reflectance') as reflectance,   pt.ordinality , gid
			FROM  acquisition_tmob_012013.riegl_pcpatch_space as p,  rc_explodeN_numbered(patch,-1) as pt 
			WHERE PC_NUmpOints(patch)>100
				AND gid BETWEEN 300000 AND 351000 
		)TO '/media/sf_E_RemiCura/DATA/test_order_octree_check_.csv'-- '/tmp/temp_pointcloud_lod.csv'
WITH csv header;


  WITH area AS (
		  SELECT ST_Centroid(patch::geometry) as geom
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p1 
		WHERE p1.gid = 300354
		LIMIT 1 
		  )
		  SELECT  gid, pc_numpoints(patch), r.points_per_level
			FROM area, acquisition_tmob_012013.riegl_pcpatch_space as p, rc_order_octree(patch,7)  AS r--, rc_explodeN_numbered(r.opatch) as pt 
			WHERE ST_DWithin(p.patch::geometry, area.geom, 5) = TRUE
