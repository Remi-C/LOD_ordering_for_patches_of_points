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
WHILE @I <= 25000  
BEGIN 
	UPDATE  benchmark_cassette_2013.riegl_pcpatch_space as rps
	SET (patch,points_per_level) = ( nv.opatch, nv.points_per_level)
	FROM  (
		SELECT p.gid, r.opatch, r.points_per_level
		FROM benchmark_cassette_2013.riegl_pcpatch_space as p 
			,rc_order_octree( p.patch , 7) as r  
		WHERE gid  BETWEEN @I AND @I+@S 
			--AND gid%2 = 0 
			AND p.points_per_level IS NULL
		) as nv
		WHERE nv.gid  = rps.gid ; 
	SET @I = @I + @S ; 
END


UPDATE  benchmark_cassette_2013.riegl_pcpatch_space as rps
	SET (patch,points_per_level) = ( nv.opatch, nv.points_per_level)
	FROM  (
		SELECT p.gid, r.opatch, r.points_per_level
		FROM benchmark_cassette_2013.riegl_pcpatch_space as p 
			,rc_order_octree( p.patch , 7) as r  
		WHERE gid  = 1156
			--AND gid%2 = 0 
		) as nv
		WHERE nv.gid  = rps.gid ; 

SELECT *, pc_numpoints(patch)
FROM benchmark_cassette_2013.riegl_pcpatch_space  ,rc_order_octree(  patch , 7) 
WHERE gid = 1156

 --ALTER TABLE benchmark_cassette_2013.riegl_pcpatch_space  ADD COLUMN points_per_level INT[]


 
DECLARE @I,@S ;
SET @I=0;
SET @S =50 ; 
WHILE @I < 25000 -- 5473129
BEGIN  
	UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET (dominant_simplified_class, proba_occurency)  = (r.simplidifed_id, r.proba_occurency)
	FROM (
		SELECT gid, f.*
		FROM benchmark_cassette_2013.riegl_pcpatch_space as p , rc_dominant_class(patch) AS f
		WHERE gid BETWEEN @I AND @I+@S
			AND --pc_numpoints(patch) > 100
				p.dominant_simplified_class IS NULL
			) as r
	WHERE riegl_pcpatch_space.gid = r.gid   ;
 
	SET @I = @I + @S ; 
END





DECLARE @I,@S ;
SET @I=0;
SET @S =50 ; 
WHILE @I < 25000 -- 5473129
BEGIN  
	
	UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET  (patch_height,height_above_laser,patch_area,reflectance_avg,nb_of_echo_avg) = 
		(COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0)  
		,  COALESCE( round(PC_PatchMin(patch, 'Z')-PC_PatchAvg(patch, 'z_origin') ,3),0 )  
		, COALESCE(round(rc_pcpatch_real_area_N(patch,85,0.06,0.2)::numeric,3),0)  
		,  COALESCE( round(PC_PatchAvg(patch, 'reflectance'),3),0 ) 
		,  COALESCE( round(PC_PatchAvg(patch, 'nb_of_echo') ,3),0)   ) 
	WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
		AND  gid BETWEEN @I AND @I+@S  
		AND patch_height IS NULL;
 
	SET @I = @I + @S ; 
END


SELECT min(gid),max(gid)
FROM benchmark_cassette_2013.riegl_pcpatch_space
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL ;


DECLARE @I,@S ;
SET @I=250000;
SET @S =100 ; 
WHILE @I < 300000 -- 5473129
BEGIN  
	
	UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET  (patch_height,height_above_laser ,reflectance_avg,nb_of_echo_avg,patch_area) 
		= 
	 ( nv.patch_height,nv.height_above_laser ,nv.reflectance_avg,nv.nb_of_echo_avg,nv.patch_area)
	 FROM (
		SELECT gid, r.*, COALESCE(round(rc_pcpatch_real_area_N(patch,85,0.06,0.2)::numeric,3),0)  as patch_area
		FROM acquisition_tmob_012013.riegl_pcpatch_space  , rc_pcpatch_compute_crude_descriptors(patch ) AS r
		WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
			AND gid BETWEEN @I AND @I+@S
		 ) AS nv
	WHERE nv.gid = riegl_pcpatch_space.gid ; 
	SET @I = @I + @S ; 
END



UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET  (patch_height,height_above_laser ,reflectance_avg,nb_of_echo_avg,patch_area) = 
 ( nv.patch_height,nv.height_above_laser ,nv.reflectance_avg,nv.nb_of_echo_avg,nv.patch_area)
 FROM (
SELECT gid, r.*, COALESCE(round(rc_pcpatch_real_area_N(patch,85,0.06,0.2)::numeric,3),0)  as patch_area
FROM acquisition_tmob_012013.riegl_pcpatch_space  , rc_pcpatch_compute_crude_descriptors(patch ) AS r
	WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
	AND gid = 1125 ) AS nv
	WHERE nv.gid = riegl_pcpatch_space.gid

 

DECLARE @I,@S ;
SET @I=0;
SET @S =100 ; 
WHILE @I <25000 
BEGIN  
	
	UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET (class_ids ,  class_weight)  = (r.class_ids, r.class_weight)
	FROM (
		SELECT gid, f.*
		FROM benchmark_cassette_2013.riegl_pcpatch_space, rc_all_classes(patch) AS f 
		WHERE gid BETWEEN @I AND @I+@S
	)as r
	WHERE riegl_pcpatch_space.gid = r.gid  ;
	SET @I = @I + @S ; 
END


 
	UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET (class_ids ,  class_weight)  = (r.class_ids, r.class_weight)
	FROM (
		SELECT gid, f.*
		FROM benchmark_cassette_2013.riegl_pcpatch_space, rc_all_classes(patch) AS f 
		WHERE gid BETWEEN 1 AND 2 
	)as r
	WHERE riegl_pcpatch_space.gid = r.gid  
