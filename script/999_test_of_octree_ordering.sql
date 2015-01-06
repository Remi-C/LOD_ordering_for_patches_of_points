---------------------------------------------
--Copyright Remi-C  15/02/2014
--
--
--This script expects a postgres >= 9.3, Postgis >= 2.0.2
--
--test of octree based ordering
--------------------------------------------

SET search_path to lod, public ;

--creating a synthetic pointcloud :
--creating a table with oid, x, y (done once and for all here)
	DROP TABLE IF EXISTS test_order_index_points;
	CREATE table test_order_index_points AS
	WITH generated_points AS (
		SELECT row_number() over() AS oid
			, x+0.5 - random()*2*110/1000   AS x
			, y+0.5 - random()*2*110/1000   AS y
			--,50+0.5 AS z--  
			, z+0.5 - random()*2*110/1000  AS z
		FROM generate_series(1,16) AS x, generate_series(1,16) AS y ,generate_series(1,7) AS z
			
		)
		, min_max AS (
			SELECT   
				  min(x)/2+max(x)/2  AS x_min
				, min(y)/2+max(y)/2  AS y_min
				, min(z)/2+max(z)/2  AS z_min
				,greatest(max(x) - min(x),max(y) - min(y),max(z) - min(z)) AS max_r 
			FROM generated_points 
			LIMIT 1 
		)	
		SELECT 
			oid
			, ( x - x_min) / max_r +0.5 as x
			, ( y - y_min) / max_r +0.5 as y
			, ( z - z_min) / max_r +0.5 as z 
			, ST_MakePoint(x,y,z) AS noisy_point
		FROM generated_points,min_max;

	--adding columns x_bf_8 and y_bf_8 if they don't exist, computing x_bf_8 and y_bf_8
		SELECT rc_CreatePbfColumn3D('test_order_index_points', 7);
		--SELECT rc_CreatePbfColumn('test_order_index_points', 5);

	--checking : 
		SELECT min(x),max(x)
		FROM test_order_index_points;
		--ORDER BY lev ASC, ord ASC; 

	--outputting the pointcloud to see it in cloud compare

-- 	COPY (
-- 		SELECT x, y, z , oid, x_bf_7, y_bf_7, z_bf_7
-- 		FROM test_order_index_points
-- 		--LIMIT 1
-- 	)
-- 	TO '/media/sf_E_RemiCura/DATA/test_order_index_points.csv'

	--computing a level 
		--DROP TABLE IF EXISTS public.test_order_index_result;
		--CREATE table public.test_order_index_result AS
			SELECT public.rc_OrderByOcTree( pointsTable:='test_order_index_points',tot_tree_level:=7);
			SELECT public.rc_OrderByOcTreeL( pointsTable:='test_order_index_points',tree_level:=1,tot_tree_level:=7);	

			SELECT public.rc_OrderByQuadTree( pointsTable:='test_order_index_points',tot_tree_level:=7)
			SELECT public.rc_OrderByQuadTreeL( pointsTable:='test_order_index_points',tree_level:=0,tot_tree_level:=5);		

	--computing the rc_P3D
	SELECT 
	FROM test_order_index_points;
	--writting result to disk to analyze in cloudcompare
	COPY 
		( SELECT x,y ,z, oid  , f.* --,ord,lev
		FROM test_order_index_points , rc_P3D(x, y,z, 1,7 ,x_bf_7,y_bf_7,z_bf_7)as f 
		ORDER BY lev, ord
		)
	TO '/media/sf_E_RemiCura/DATA/test_order_index_points.csv'-- '/tmp/temp_pointcloud_lod.csv'
	WITH csv header;
		
	--computing the ordering for all level
		DROP TABLE IF EXISTS public.test_order_index_result;
		CREATE table public.test_order_index_result AS
			WITH serie AS (
				SELECT generate_series(0,6) AS tree_level
			)
			,the_order AS (
				SELECT t_o.tree_level, public.rc_OrderByOcTreeL( pointsTable:='test_order_index_points',tree_level:=t_o.tree_level,tot_tree_level:=6) ordering_result
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


			