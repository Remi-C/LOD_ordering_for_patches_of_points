
SET search_path to lod, public ; 

DROP FUNCTION IF EXISTS public.rc_OrderPatchByQuadTree( a_patch PCPATCH , tot_tree_level INT,OUT o_patch PCPATCH, OUT result_per_level int[]);
		CREATE OR REPLACE FUNCTION public.rc_OrderPatchByQuadTree( a_patch PCPATCH , tot_tree_level INT,OUT o_patch PCPATCH,  OUT result_per_level int[])
		 AS
		$BODY$
		--this function computes quad tree order for points inside a patch and ouput the same patch with the points ordered following quad tree
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
							, lower(x_range)  AS x_min
							,  lower(y_range)  AS y_min
							,upper(x_range) - lower(x_range) as x_r
							,upper(y_range) - lower(y_range) AS y_r
							, x_range, y_range
						FROM rc_compute_range_for_a_patch(a_patch , 'x') as x_range
						, rc_compute_range_for_a_patch(a_patch , 'y') as y_range
						LIMIT 1 
					)	
					,points AS (
						SELECT row_number() over() AS oid,   ST_Force2D(points::geometry) AS points
						FROM PC_Explode(a_patch) AS points 
						--LIMIT 100
					)
					SELECT oid
						, (ST_X(points)- x_min)/x_r  AS x
						, (ST_Y(points) - y_min)/y_r AS y --we center/scale to 0,1, then scale to tree width
					FROM points,min_max;
			--order this points by quad tree

				_r :=public.rc_OrderByQuadTree( 'temp_ordering_patch'::regclass , tot_tree_level);
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

				--DROP TABLE IF EXISTS temp_ordering_patch;
		
		return;
		END;
		$BODY$
		LANGUAGE plpgsql STRICT VOLATILE;

		DROP TABLE IF EXISTS temp_visu_patch;
		CREATE TABLE  temp_visu_patch AS 
			SELECT    n.ordinality, n.point::geometry , r.result_per_level
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p
				, public.rc_OrderPatchByQuadTree( p.patch , 12) as r 
				, rc_exploden_numbered(r.o_patch,-1) AS n
			WHERE --p.gid = 368290; --small patch
					-- p.gid = 178749 ;  --big patch
					p.gid = 364966 --big patch problematic
 
		SELECT  gid
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p 
		WHERE pc_numpoints(patch) BETWEEN 1000 AND 10000
			AND  upper(rc_compute_range_for_a_patch(patch , 'z')) - lower(rc_compute_range_for_a_patch(patch , 'z')) BETWEEN 0 AND 0.5
		LIMIT 1  ; 


------cum sum
			WITH pow AS (
				SELECT s,power(4,s) as pow4,power(2,s) as pow2
				FROM generate_series(0,8) s
			)
			SELECT s,pow2,pow4, sum(pow2) over(order by s) cumpow2, sum(pow4) over(order by s) cumpow4
			FROM pow;
----------------
