﻿---------------------------------------------
--Copyright Remi-C  22/10/2013
--
--
--This script expects a postgres >= 9.3, Postgis >= 2.0.2, postgis topology enabled
--
--
--------------------------------------------



----
--better functional organisation
-- how odes it work :
--input : table with uid::int, x::numeric, y::numeric  , parameters (tree depth86)
--output : a "table" with uid int and order int, where uid is the same as input uid, and order are non duplicates int positive ordeing the data following the desiderated quad tree order
----
/*
	--creating a table with oid, x, y (done once and for all here)
		DROP TABLE IF EXISTS public.test_order_index_points;
		CREATE table public.test_order_index_points AS
		WITH generated_points AS (
			SELECT  id_qgis AS oid
				, ST_X(geom) + random()*2*110/1000 - random()*2*110/1000 AS x
				, ST_Y(geom) + random()*2*110/1000 - random()*2*110/1000  AS y
				, geom 
			FROM (
				SELECT row_number() over() AS id_qgis,  gcol, grow,geom 
				FROM ST_RegularGrid(ST_GeomFromText('LINESTRING(140 570, 141 571)',0),0.003,0.003)
				) as foo2
			)
			SELECT *, ST_MakePoint(x,y) AS noisy_point
			FROM generated_points;

	--adding columns x_bf_8 and y_bf_8 if they don't exist, computing x_bf_8 and y_bf_8
		SELECT rc_CreatePbfColumn('public.test_order_index_points', 6);
	--computing the ordering for all level
		DROP TABLE IF EXISTS public.test_order_index_result;
		CREATE table public.test_order_index_result AS
			WITH serie AS (
				SELECT generate_series(0,6) AS tree_level
			)
			,the_order AS (
				SELECT t_o.tree_level, public.rc_OrderByQuadTreeL( pointsTable:='test_order_index_points',tree_level:=t_o.tree_level,tot_tree_level:=6) ordering_result
				FROM serie t_o--,  public.rc_OrderByQuadTreeL( pointsTable:='test_order_index_points',tree_level:=t_o.tree_level,tot_tree_level:=6) f(ordering_result)
			)
			,total_result AS (
				SELECT points.*,t_o.tree_level, (t_o.ordering_result)[1] AS order_oid, (t_o.ordering_result)[2] AS ord
				FROM public.test_order_index_points AS points LEFT outer JOIN the_order t_o ON ( points.oid = (t_o.ordering_result)[1] )
				ORDER BY tree_level, ord, points.oid
			)
			,ordered_result AS (
				SELECT DISTINCT ON (oid ) oid, noisy_point, tree_level,ord
				FROM total_result
				ORDER BY  oid ASC, tree_level ASC , ord ASC 
			)
			SELECT *, row_number() over (ORDER BY tree_level, ord) AS id_qgis
			FROM ordered_result
			ORDER BY tree_level, ord

*/

--------test on riegl_pcpatch----------------
--
--
--
--
-------------------------------------------------
	--adding a column to old number of point per level 
	ALTER TABLE acquisition_tmob_012013.riegl_pcpatch_space ADD COLUMN points_per_level int[];
	
	CREATE INDEX ON acquisition_tmob_012013.riegl_pcpatch_space (points_per_level);

	
	--updating patch with good order :
	WITH reordered_patch AS (
		SELECT gid, public.rc_OrderPatchByQuadTree( patch , 7) AS result
		FROM acquisition_tmob_012013.riegl_pcpatch_space

	UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET (patch, points_per_level)  
		= (  result.o_patch, result.result_per_level)
		FROM public.rc_OrderPatchByQuadTree( patch , 7) AS result
		WHERE PC_NumPoints(patch)>350000 AND PC_NumPoints(patch)<1000000;	--600sec

	UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET (patch, points_per_level)  
		= (  result.o_patch, result.result_per_level)
		FROM public.rc_OrderPatchByQuadTree( patch , 7) AS result
		WHERE PC_NumPoints(patch)>=200000 AND PC_NumPoints(patch)<350000;	--677sec

	UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET (patch, points_per_level)  
		= (  result.o_patch, result.result_per_level)
		FROM public.rc_OrderPatchByQuadTree( patch , 7) AS result
		WHERE PC_NumPoints(patch)>=150000 AND PC_NumPoints(patch)<200000;	--263

	UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET (patch, points_per_level)  
		= (  result.o_patch, result.result_per_level)
		FROM public.rc_OrderPatchByQuadTree( patch , 7) AS result
		WHERE PC_NumPoints(patch)>=100000 AND PC_NumPoints(patch)<150000;	--286

	UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET (patch, points_per_level)  
		= (  result.o_patch, result.result_per_level)
		FROM public.rc_OrderPatchByQuadTree( patch , 7) AS result
		WHERE PC_NumPoints(patch)>=75000 AND PC_NumPoints(patch)<100000;	--300	


		WITH unnested_number_of_points AS (
		SELECT (SELECT sum(t) FROM  unnest(points_per_level[1:4]) AS t)  AS nb --gid --,PC_NumPoints(patch) --, points_per_level, result.result_per_level
		FROM acquisition_tmob_012013.riegl_pcpatch_space--, public.rc_OrderPatchByQuadTree( patch , 7) AS result
		WHERE PC_NumPoints(patch)>=85 AND PC_NumPoints(patch)<75000
		AND points_per_level IS NOT NULL
		)
		SELECT sum(nb)
		FROM unnested_number_of_points
		LIMIT 1000
		--7 millions



			

--////////////////////////
--clean version : creating a data table , creating function to give order, joining with data table and printing in qgis
	DROP TABLE IF EXISTS temp_points_in_patch_ordered;
	CREATE TABLE temp_points_in_patch_ordered AS 
	SELECT  *,row_number() over(PARTITION BY gid ORDER BY qgis_id ASC) as ord 
	FROM (
		SELECT row_number() over() as qgis_id,gid, points_per_level, point::geometry
		FROM acquisition_tmob_012013.riegl_pcpatch_space ,  rc_ExplodeN( patch, (SELECT sum(t) FROM unnest(points_per_level[1:4]) AS t)) as point
		WHERE PC_NumPoints(patch)>=85 AND PC_NumPoints(patch)<75000 AND points_per_level IS NOT NULL
		--LIMIT 100 
		) as foo;
		CREATE INDEX ON temp_points_in_patch_ordered USING GIST(point);
		VACUUM ANALYZE temp_points_in_patch_ordered;

		


	DROP FUNCTION IF EXISTS public.rc_ExplodeN( a_patch PCPATCH , n bigint);
		CREATE OR REPLACE FUNCTION  public.rc_ExplodeN( a_patch PCPATCH , n bigint)
		RETURNS SETOF pcpoint AS
		$BODY$
		--this function is a wrapper around pc_explode to limit the number of points it returns	
		DECLARE
		BEGIN
			RETURN QUERY 
				SELECT PC_Explode(a_patch)
				LIMIT n;
		return;
		END;
		$BODY$
		LANGUAGE plpgsql STRICT VOLATILE;

	SELECT public.rc_ExplodeN(patch, 10)
	FROM acquisition_tmob_012013.riegl_pcpatch_space
	WHERE gid=120;



DROP FUNCTION IF EXISTS public.rc_ExplodeN_numbered( a_patch PCPATCH , n bigint);
		CREATE OR REPLACE FUNCTION  public.rc_ExplodeN_numbered( a_patch PCPATCH , n bigint)
		RETURNS table(num bigint , point pcpoint ) AS
		$BODY$
		--this function is a wrapper around pc_explode to limit the number of points it returns	
		DECLARE
		BEGIN
			RETURN QUERY 
				SELECT generate_series(1, n), PC_Explode(a_patch)
				LIMIT n;
		return;
		END;
		$BODY$
		LANGUAGE plpgsql STRICT VOLATILE;


SELECT public.rc_ExplodeN_numbered(patch, 10)
	FROM acquisition_tmob_012013.riegl_pcpatch_space
	WHERE gid=120;


	SELECT public.rc_ExplodeN_numbered(patch, 10)
	FROM acquisition_tmob_012013.riegl_pcpatch_space
	WHERE gid=120;

	WITH patch AS (
		SELECT generate_series(1, PC_NumPoints(patch),1), public.pc_explode(patch)
		FROM acquisition_tmob_012013.riegl_pcpatch_space
		WHERE gid=120
	)

	SELECT public.pc_explode(patch)
		FROM acquisition_tmob_012013.riegl_pcpatch_space
		WHERE gid=120