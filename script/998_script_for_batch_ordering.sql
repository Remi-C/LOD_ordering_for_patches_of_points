---------------------------------------------
--Copyright Remi-C  15/02/2014
--
--
--This script expects a postgres >= 9.3, Postgis >= 2.0.2 , pointcloud
--
--
--------------------------------------------


SELECT max(gid)
FROM acquisition_tmob_012013.riegl_pcpatch_space

DECLARE @I,@S ;
SET @I=300000;
SET @S = 100;--10
WHILE @I <  5473129
BEGIN 
	UPDATE  acquisition_tmob_012013.riegl_pcpatch_space as rps
	SET (patch,points_per_level) = ( nv.o_patch, nv.result_per_level)
	FROM  (
		SELECT p.gid, r.o_patch, r.result_per_level
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p
			, public.rc_OrderPatchByOcTree( p.patch , 7) as r  
		WHERE gid  BETWEEN @I AND @I+@S 
			AND gid%2 = 0
			AND pc_numpoints(patch) > 100
		) as nv
		WHERE nv.gid  = rps.gid ; 
	SET @I = @I + @S ; 
END


			SELECT    n.ordinality, n.point::geometry , r.result_per_level
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p
				, public.rc_OrderPatchByOcTree( p.patch , 6) as r 
				, rc_exploden_numbered(r.o_patch,-1) AS n
			WHERE --p.gid = 368290; --small patch
					 p.gid = 178749 ;  --big patch
					-- p.gid = 364966 --big patch problematic


	WITH new_values AS (
		SELECT p.gid, r.o_patch, r.result_per_level
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p
			, public.rc_OrderPatchByOcTree( p.patch , 7) as r  
		WHERE gid  BETWEEN 2 AND 10 
			AND pc_numpoints(patch) > 100 
	)
	UPDATE  acquisition_tmob_012013.riegl_pcpatch_space as rps
	SET (patch,points_per_level) = ( nv.o_patch, nv.result_per_level)
	FROM  new_values as nv
		WHERE nv.gid  = rps.gid  



		WITH new_values AS (
		SELECT p.gid, r.o_patch, r.result_per_level
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p
			, public.rc_OrderPatchByOcTree( p.patch , 7) as r  
		WHERE gid  BETWEEN @I AND @I+@S 
			AND pc_numpoints(patch) > 100 
	)
	UPDATE  acquisition_tmob_012013.riegl_pcpatch_space as rps
	SET (patch,points_per_level) = ( nv.o_patch, nv.result_per_level)
	FROM  new_values as nv
		WHERE nv.gid  = rps.gid ;
	SET @I = @I + @S ; 
					