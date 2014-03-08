---------------------------------------------
--Copyright Remi-C  22/10/2013
--
--
--This script expects a postgres >= 9.3, Postgis >= 2.0.2
--
--
--------------------------------------------



----
--better functional organisation
-- how does it work :
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



--///////////////////////// support functions


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



--////////////////////////////////////////////////
--chained operations from start

--create function explodeN and explodeN_numbered

-- create function public.rc_OrderPatchByQuadTree and required dependencies

--adding the column to data table :
	ALTER TABLE acquisition_tmob_012013.riegl_pcpatch_space ADD COLUMN points_per_level int[];
	CREATE INDEX ON acquisition_tmob_012013.riegl_pcpatch_space (points_per_level);
	
--what kind of patches do we want to convert?
	SELECT sum(pc_NumPoints(patch))
	FROM acquisition_tmob_012013.riegl_pcpatch_space
	WHERE PC_NumPoints(patch)>85
	AND gid > 360000 AND gid < 36000

	
 set client_min_messages to warning;
--compute ordering for a couple of patches
UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET (patch, points_per_level)  
		= (  result.o_patch, result.result_per_level)
		FROM public.rc_OrderPatchByQuadTree( patch , 7) AS result
		WHERE PC_NumPoints(patch)>85
		AND gid >= 360000 AND gid < 365000


-- computing done in several transaction to limit memory consumption

DECLARE @I; -- Variable names begin with a @
SET @I = 384900; -- @I is an integer
WHILE @I <= 473129
BEGIN
	UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET (patch, points_per_level)  
		= (  result.o_patch, result.result_per_level)
		FROM public.rc_OrderPatchByQuadTree( patch , 7) AS result
		WHERE PC_NumPoints(patch)>85
		AND gid >= @I AND gid < (@I + 100);
   SET @I = @I + 100;
END


--exploding the patches with LOD into points to a new table

	DROP TABLE IF EXISTS temp_points_in_patch_ordered_numbered;
	CREATE TABLE temp_points_in_patch_ordered_numbered AS 
	SELECT  row_number() over() as qgis_id , points_per_level, qgis_id AS ord, gid, point
	FROM (
		SELECT (pointt).num as qgis_id,gid, points_per_level, (pointt).point::geometry
		FROM acquisition_tmob_012013.riegl_pcpatch_space ,  rc_ExplodeN_numbered( patch, (SELECT sum(t) FROM unnest(points_per_level[1:5]) AS t)) as pointt
		WHERE PC_NumPoints(patch)>85
		AND gid >= 360000 AND gid < 380000
		AND points_per_level IS NOT NULL
		--LIMIT 100 
		) as foo
		LIMIT 3000000;
		CREATE INDEX ON temp_points_in_patch_ordered_numbered USING GIST(point);
		VACUUM ANALYZE temp_points_in_patch_ordered_numbered;

--exporting data for external visualisation


COPY 
	( SELECT ST_X(point) AS X, ST_Y(point) AS Y,ST_Z(point) AS Z,ord, gid
	FROM temp_points_in_patch_ordered_numbered
	)
TO '/media/sf_E_RemiCura/DATA/tmp_pointcloud_lod.csv'-- '/tmp/temp_pointcloud_lod.csv'
WITH csv header;


COPY 
	( 
	SELECT ST_X(point) AS X, ST_Y(point) AS Y,ST_Z(point) AS Z, gid
	FROM (
		SELECT PC_Explode(patch )::geometry As  point, gid
		FROM acquisition_tmob_012013.riegl_pcpatch_space 
		WHERE PC_NumPoints(patch)>85
			AND gid >= 369310 AND gid < 372838
			AND points_per_level IS NOT NULL
		) AS toto
		--LIMIT 1
	)
TO '/media/sf_E_RemiCura/DATA/tmp_pointcloud_total.csv'-- '/tmp/temp_pointcloud.csv'
WITH csv header;


--how many patch have been LOD-ed ?

		SELECT count(*)
		FROM acquisition_tmob_012013.riegl_pcpatch_space 
		WHERE points_per_level IS NOT NULL
			AND PC_NumPoints(patch)>85


--some profiling on the time to create LOD
	--getting some big patches
		SELECT gid
		FROM acquisition_tmob_012013.riegl_pcpatch_space 
		WHERE PC_NumPoints(patch)>10000
		AND gid > 380000
		LIMIT 10

	--clearing stats :
	SELECT pg_stat_reset();
	
	--updating the patches
		UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET (patch, points_per_level)  
		= (  result.o_patch, result.result_per_level)
		FROM public.rc_OrderPatchByQuadTree( patch , 7) AS result
		WHERE PC_NumPoints(patch)>10000
		--AND gid IN (391820,389893,394377,396616,468230,387036,441103,472601,386876,389797)
		AND gid IN (380003,405432,380312,411512,405829,399971,420812,411429,411294,398664);
		

	--viewing result$
	SELECT *
	FROM pg_stat_user_functions
	ORDER BY self_time DESC

	--64 sec for 10 >10kpoints patches
	--usage :		_ 30 % : rc_orderbyquadtreel --> include the grouping and ordering by distance
	--			_ 30 % : rc_p  --> stupid computing, but lot's of it. ==> should be put to C
	--			_15 % : rc_orderpatchbyquadtree  --> include patch exploding and recopy



--------- testing the octree ordering

	UPDATE acquisition_tmob_012013.riegl_pcpatch_space SET (patch, points_per_level)  
		= (  result.o_patch, result.result_per_level)
		FROM public.rc_OrderPatchByOcTree( patch , 7) AS result
		WHERE gid = 378957

	DROP TABLE IF EXISTS temp_points_in_patch_ordered_numbered;
	CREATE TABLE temp_points_in_patch_ordered_numbered AS 
	SELECT  row_number() over() as qgis_id , points_per_level, qgis_id AS ord, gid, point
	FROM (
		SELECT (pointt).num as qgis_id,gid, points_per_level, (pointt).point::geometry
		FROM acquisition_tmob_012013.riegl_pcpatch_space ,  rc_ExplodeN_numbered( patch, (SELECT sum(t) FROM unnest(points_per_level[1:5]) AS t)) as pointt
		WHERE gid = 378957--LIMIT 100 
		) as foo;
		
		CREATE INDEX ON temp_points_in_patch_ordered_numbered USING GIST(point);
		VACUUM ANALYZE temp_points_in_patch_ordered_numbered;

--exporting data for external visualisation

COPY 
	( SELECT ST_X(point) AS X, ST_Y(point) AS Y,ST_Z(point) AS Z,ord, gid
	FROM temp_points_in_patch_ordered_numbered
	)
TO '/media/sf_PROJETS/tmp_pointcloud_lod.csv'-- '/tmp/temp_pointcloud_lod.csv'
WITH csv header;