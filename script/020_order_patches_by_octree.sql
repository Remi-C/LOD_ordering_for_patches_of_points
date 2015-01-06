
SET search_path to lod, public ;



DROP FUNCTION IF EXISTS public.rc_OrderPatchByOcTree( a_patch PCPATCH , tot_tree_level INT,OUT o_patch PCPATCH, OUT result_per_level int[]);
		CREATE OR REPLACE FUNCTION public.rc_OrderPatchByOcTree( a_patch PCPATCH , tot_tree_level INT,OUT o_patch PCPATCH,  OUT result_per_level int[])
		 AS
		$BODY$
		--this function computes oc tree order for points inside a patch and ouput the same patch with the points ordered following quad tree
		--It expects as input 
			--a patch of a given schema
			
		DECLARE
		_q text :='';
		_r int[];
		_pts_nb_in_current_level BIGINT;
		_end_indice int := 0;
		_tot_points numeric;
		BEGIN
			--create a temp table with points inside patch
			--order this points by quad tree
			--make a patch with this points in the quad tree order


			--create a temp table with points inside patch
				/*DROP TABLE IF EXISTS temp_ordering_patch;
				CREATE TEMP TABLE temp_ordering_patch AS 
					WITH points AS (
						SELECT row_number() over() AS oid,  points
						FROM PC_Explode(a_patch) AS points
					)
					SELECT oid, Pc_Get(points,'x') AS x, Pc_Get(points,'y') AS y, ST_MakePoint( Pc_Get(points,'x'), Pc_Get(points,'y')) as point
					FROM points;
					*/
				DROP  TABLE IF EXISTS temp_ordering_patch;
				CREATE  TEMP TABLE temp_ordering_patch AS 
					WITH min_max AS (
						SELECT  (upper(x_range) + lower(x_range))/2.0 AS x_avg
							, (upper(y_range) - lower(y_range))/2.0 AS y_avg 
							, (upper(z_range) - lower(z_range))/2.0 AS z_avg 
							--, lower(x_range)/2.0 + upper(x_range)/2.0  AS x_min
							--, lower(y_range)/2.0 + upper(y_range)/2.0  AS y_min
							--, lower(z_range)/2.0 + upper(z_range)/2.0  AS z_min
							, lower(x_range) AS x_min
							, lower(y_range) AS y_min
							, lower(z_range) AS z_min
							
							,CASE WHEN upper(x_range) - lower(x_range) = 0 THEN 1 ELSE upper(x_range) - lower(x_range) END as x_r
							,CASE WHEN upper(y_range) - lower(y_range) = 0 THEN 1 ELSE upper(y_range) - lower(y_range) END AS y_r
							,CASE WHEN upper(z_range) - lower(z_range) = 0 THEN 1 ELSE upper(z_range) - lower(z_range) END AS z_r
							,greatest(upper(x_range) - lower(x_range),upper(y_range) - lower(y_range),upper(z_range) - lower(z_range)) AS max_r
							, x_range, y_range , z_range
						FROM rc_compute_range_for_a_patch(a_patch , 'x') as x_range
						, rc_compute_range_for_a_patch(a_patch , 'y') as y_range
							, rc_compute_range_for_a_patch(a_patch , 'z') as z_range
						LIMIT 1 
					)	
					, points AS (
						SELECT row_number() over() AS oid,   ST_Force3D(points::geometry) AS points
						FROM PC_Explode(a_patch) AS points 
					)
					SELECT oid
						, (ST_X(points)- x_min) /CASE WHEN max_r !=0 then max_r else 1 end  AS x --/x_r  AS x
						, (ST_Y(points)- y_min) /CASE WHEN max_r !=0 then max_r else 1 end  AS y --/y_r  AS y
						, (ST_Z(points)- z_min) /CASE WHEN max_r !=0 then max_r else 1 end  AS z --/z_r  AS z --, points as point --commented out : not needed for the following
					FROM points,min_max;
			--order this points by quad tree 
				_r :=public.rc_OrderByOcTree( 'temp_ordering_patch'::regclass , tot_tree_level);
				--RAISE NOTICE '_r :%',_r;
			--make a patch with this points in the quad tree order
				SELECT PC_Patch(point ORDER BY lev ASC, ord asc) as patch INTO o_patch
				FROM (
					WITH points AS (
							SELECT row_number() over() AS oid,  points
							FROM PC_Explode(a_patch) AS points
						)
						SELECT lev,ord, p.points aS point
						FROM  points AS p
							LEFT OUTER JOIN temp_ordering_patch AS top ON  (top.oid = p.oid)
						--FROM temp_ordering_patch as top LEFT OUTER JOIN points AS p ON (top.oid = p.oid)
				) AS ordering; 

				result_per_level := _r;

				DROP TABLE IF EXISTS temp_ordering_patch;
		
		return;
		END;
		$BODY$
		LANGUAGE plpgsql STRICT VOLATILE;

		/*
		DROP TABLE IF EXISTS temp_visu_patch;
		CREATE TABLE  temp_visu_patch AS 
		WITH result AS (
			SELECT    public.rc_OrderPatchByOcTree( p.patch , 6) as r, PC_NumPoints(patch) as num
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p
			WHERE p.gid = 		
			) 
			SELECT row_number() over() AS oid,  1.0/(row_number() over() )AS i_gid,points::geometry, (r).result_per_level, num
			FROM result, PC_Explode((r).o_patch) AS points;

			SELECT *,PC_NUmPoints(patch) as num
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p, public.rc_OrderPatchByQuadTree( p.patch , 6) as r
			WHERE p.gid = 203665

			SELECT *, PC_NUmPoints(patch) as num
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p
			WHERE p.gid = 203665
		*/

		DROP TABLE IF EXISTS temp_visu_patch;
		CREATE TABLE  temp_visu_patch AS 
			SELECT    n.ordinality, n.point::geometry , r.result_per_level
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p
				, public.rc_OrderPatchByOcTree( p.patch , 6) as r 
				, rc_exploden_numbered(r.o_patch,-1) AS n
			WHERE --p.gid = 368290; --small patch
					 p.gid = 178749 ;  --big patch
					-- p.gid = 364966 --big patch problematic

		DROP TABLE IF EXISTS temp_visu_patch;
		CREATE TABLE  temp_visu_patch AS 
			SELECT    n.ordinality, n.point::geometry , r.result_per_level
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p
				, public.rc_OrderPatchByOcTree( p.patch , 6) as r 
				, rc_exploden_numbered(r.o_patch,-1) AS n
			WHERE --p.gid = 368290; --small patch
					 p.gid = 178749 ;  --big patch
					-- p.gid = 364966 --big patch problematic

		SELECT sum(PC_NumPoints(patch))
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p
		WHERE p.gid BETWEEN 0 AND 10000



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
 SELECT pc_get(pt,'x') AS x, pc_get(pt,'y') AS y,pc_get(pt,'z') AS z, pc_get(pt,'reflectance') as reflectance,pc_get(pt,'gps_time') as gps_time ,  ord,gid  
		FROM area, acquisition_tmob_012013.riegl_pcpatch_space as p,  public.rc_OrderPatchByOcTree( p.patch , 7) as r,  rc_ExplodeN_numbered(r.o_patch, -1) as f(ord,pt) 
		WHERE ST_DWithin(p.patch::geometry, area.geom, 5) = TRUE


) TO '/media/sf_E_RemiCura/DATA/test_order_index_points_octree_old_tech.csv'-- '/tmp/temp_pointcloud_lod.csv'
WITH csv header;
--4700 sec
--for 53 137 909 points 
-- 11k pts/sec
rc_ExplodeN_numbered

-- 		SELECT gid, PC_NUmPoints(patch) as num
-- 		FROM acquisition_tmob_012013.riegl_pcpatch_space as p
-- 		WHERE p.gid > 360000 and p.gid<380000
-- 		ORDER BY PC_NUmPoints(patch) DESC
-- 		LIMIT 100;
-- 		

------cum sum
			WITH pow AS (
				SELECT s,power(8,s) as pow
				FROM generate_series(0,8) s
			)
			SELECT s,pow,sum(pow) over(order by s)
			FROM pow;
----------------

-- 			WITH pow AS (
-- 				SELECT s,power(8,s) as pow
-- 				FROM generate_series(0,8) s
-- 			)
-- 			SELECT s,pow,sum(pow) over(order by s)
-- 			FROM pow;