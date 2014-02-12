
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
				CREATE TEMP TABLE temp_ordering_patch AS 
					WITH points AS (
						SELECT row_number() over() AS oid,   ST_Force2D(points::geometry) AS points
						FROM PC_Explode(a_patch) AS points
					)
					SELECT oid,ST_X(points) AS x, ST_Y(points) AS y --, points as point --commented out : not needed for the following
					FROM points;
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
						FROM temp_ordering_patch as top LEFT OUTER JOIN points AS p ON (top.oid = p.oid)
				) AS ordering; 

				result_per_level := _r;

				DROP TABLE IF EXISTS temp_ordering_patch;
		
		return;
		END;
		$BODY$
		LANGUAGE plpgsql STRICT VOLATILE;

		DROP TABLE IF EXISTS temp_visu_patch;
		CREATE TABLE  temp_visu_patch AS 
		WITH result AS (
			SELECT    public.rc_OrderPatchByQuadTree( p.patch , 6) as r, PC_NUmPoints(patch) as num
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p
			WHERE p.gid = 203665
			) 
			SELECT row_number() over() AS oid,  1.0/(row_number() over() )AS i_gid,points::geometry, (r).result_per_level, num
			FROM result, PC_Explode((r).o_patch) AS points;

			SELECT *,PC_NUmPoints(patch) as num
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p, public.rc_OrderPatchByQuadTree( p.patch , 6) as r
			WHERE p.gid = 203665

			SELECT *, PC_NUmPoints(patch) as num
			FROM acquisition_tmob_012013.riegl_pcpatch_space as p
			WHERE p.gid = 203665


------cum sum
			WITH pow AS (
				SELECT s,power(4,s) as pow
				FROM generate_series(0,8) s
			)
			SELECT s,pow,sum(pow) over(order by s)
			FROM pow;
----------------
