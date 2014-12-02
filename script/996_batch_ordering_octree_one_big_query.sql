---------------------------------------------
--Copyright Remi-C  15/02/2014
--
--
--This script expects a postgres >= 9.3, Postgis >= 2.0.2 , pointcloud
--
--
--------------------------------------------
SET search_path to benchmark_cassette_2013,lod, public; 

SELECT max(gid)
FROM benchmark_cassette_2013.riegl_pcpatch_space

DECLARE @I,@S ;
SET @I=0;
SET @S =50 ; 
WHILE @I <= 473129  
BEGIN 
	UPDATE  acquisition_tmob_012013.riegl_pcpatch_space as rps
	SET (patch,points_per_level) = ( nv.opatch, nv.points_per_level)
	FROM  (
		SELECT p.gid, r.opatch, r.points_per_level
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p 
			,rc_order_octree( p.patch , 7) as r  
		WHERE gid  BETWEEN @I AND @I+@S 
			--AND gid%2 = 0
			AND pc_numpoints(patch) <= 100
			AND pc_numpoints(patch) >= 30
		) as nv
		WHERE nv.gid  = rps.gid ; 
	SET @I = @I + @S ; 
END


 --ALTER TABLE benchmark_cassette_2013.riegl_pcpatch_space  ADD COLUMN points_per_level INT[]


 
DECLARE @I,@S ;
SET @I=6000;
SET @S =50 ; 
WHILE @I < 12000 -- 5473129
BEGIN  
	UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET (dominant_simplified_class, proba_occurency)  = (r.simplidifed_id, r.proba_occurency)
	FROM (
		SELECT gid, f.*
		FROM benchmark_cassette_2013.riegl_pcpatch_space, rc_dominant_class(patch) AS f
		WHERE gid BETWEEN @I AND @I+@S
			AND pc_numpoints(patch) > 100
			) as r
	WHERE riegl_pcpatch_space.gid = r.gid   ;
 
	SET @I = @I + @S ; 
END