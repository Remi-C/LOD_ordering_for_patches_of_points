---------------------------------------------
--Copyright Remi-C  22/03/2014
--
--
--This script expects a postgres >= 9.3, Postgis >= 2.0.2, pointcloud >= 1.0
--
--This script test each component of the LOD ordering process
--------------------------------------------


	--testing 
	--point related
		--public.rc_OrderByQuadTree( pointsTable regclass, tot_tree_level INT,OUT result_per_level int[]);
		--public.rc_OrderByQuadTreeL( pointsTable regclass,  tree_level INT, tot_tree_level INT);
		-- public.rc_CreatePbfColumn(points_table regclass, tot_tree_level INT, OUT columns_added BOOLEAN)
		-- public.rc_P(x DOUBLE PRECISION, y DOUBLE PRECISION,tree_level INT, tot_tree_level INT, x_bf int,  y_bf int)

	--patch related
		--public.rc_OrderPatchByQuadTree( a_patch PCPATCH , tot_tree_level INT,OUT o_patch PCPATCH, OUT result_per_level int[]);


	--testing strategy :
		--create a table with regularly placed points, keeping there index (x,y in grid)
		--add goal ordering 
		--add a little noise

			--check create pbf column
			--check p
			--check the ordering 

		--create a table with regularly place points :
		SELECT setseed(0.894216);
		
		DROP TABLE IF EXISTS temp_utest_lod ;
		CREATE TABLE temp_utest_lod AS 
			WITH ind AS (
				SELECT x,y
				FROM generate_series(1,33) AS x, generate_series(1,25) AS y
				)
			--SELECT x,y,x%8,y%8
			--FROM ind
			,lev AS (
				SELECT x,y,
					CASE WHEN (x+16)%32=0 AND (y+16)%32=0 THEN 0
					WHEN (x+8)%16=0 AND (y+8)%16=0 THEN 1
					WHEN (x+4)%8=0 AND (y+4)%8=0 THEN 2
					WHEN (x+2)%4=0 AND (y+2)%4=0 THEN 3
					WHEN (x+1)%2=0 AND (y+1)%2=0 THEN 4
					WHEN x%1=0 AND y%1=0 THEN 5
					END AS lev 
				FROM ind
				)
			,noise AS (
				SELECT  x+random()/4.0 AS x, y+random()/4.0 AS y,lev
				FROM lev
			) 
			SELECT row_number() over() as oid, x AS x,y AS y,ST_MakePoint(x,y) AS geom, lev
			FROM noise ;

			--adding the ùcolumn for index
			SELECT public.rc_CreatePbfColumn('temp_utest_lod', 5);


			--checking that predicted index is correct : should return nothing
			SELECT count(*)
			FROM temp_utest_lod
			WHERE (x-x_bf_5)::int!=1 OR (y-y_bf_5)::int!=1; 

				--cheking the rc_P function :
					--preparing table :
					ALTER TABLE temp_utest_lod ADD COLUMN distance_0 bigint, ADD COLUMN x_bl_0 INT, ADD COLUMN y_bl_0 INT
						,ADD COLUMN  x_bm_0 INT, ADD COLUMN  y_bm_0 INT ;
					ALTER TABLE temp_utest_lod ADD COLUMN distance_1 bigint, ADD COLUMN x_bl_1 INT, ADD COLUMN y_bl_1 INT
						,ADD COLUMN  x_bm_1 INT, ADD COLUMN  y_bm_1 INT ;
					/*ALTER TABLE temp_utest_lod ADD COLUMN distance_2 bigint, ADD COLUMN x_bl_2 INT, ADD COLUMN y_bl_2 INT
						,ADD COLUMN  x_bm_2 INT, ADD COLUMN  y_bm_2 INT ;
					ALTER TABLE temp_utest_lod ADD COLUMN distance_3 bigint, ADD COLUMN x_bl_3 INT, ADD COLUMN y_bl_3 INT
						,ADD COLUMN  x_bm_3 INT, ADD COLUMN  y_bm_3 INT ;
					ALTER TABLE temp_utest_lod ADD COLUMN distance_4 bigint, ADD COLUMN x_bl_4 INT, ADD COLUMN y_bl_4 INT
						,ADD COLUMN  x_bm_4 INT, ADD COLUMN  y_bm_4 INT ;
					ALTER TABLE temp_utest_lod ADD COLUMN distance_5 bigint, ADD COLUMN x_bl_5 INT, ADD COLUMN y_bl_5 INT
						,ADD COLUMN  x_bm_5 INT, ADD COLUMN  y_bm_5 INT ;*/

					--updating with distance
					WITH l0 AS (
						SELECT temp_utest_lod.oid, rc.*
						FROM  temp_utest_lod, rc_P(x  , y  ,0, 5,0,-4,32,24, x_bf_5,  y_bf_5 ) as rc
						) 
					UPDATE  temp_utest_lod SET (distance_0, x_bl_0, y_bl_0, x_bm_0, y_bm_0)
						= (l0.distance, l0.x_bl, l0.y_bl, l0.x_bm, l0.y_bm) 
						FROM l0 
						WHERE l0.oid = temp_utest_lod.oid;
					WITH l1 AS (
						SELECT temp_utest_lod.oid, rc.*
						FROM  temp_utest_lod, rc_P(x  , y  ,1, 5,0,-4,32,24, x_bf_5,  y_bf_5 ) as rc
						) 
					UPDATE  temp_utest_lod SET (distance_1, x_bl_1, y_bl_1, x_bm_1, y_bm_1)
						= (l1.distance, l1.x_bl, l1.y_bl, l1.x_bm, l1.y_bm) 
						FROM l1 
						WHERE l1.oid = temp_utest_lod.oid;
					--visual check in qgis.


					SELECT temp_utest_lod.*, rc.*
					FROM  temp_utest_lod, rc_P(x  , y  ,0, 5,0,-4,32,24, x_bf_5,  y_bf_5 ) as rc;
					
				SELECT temp_utest_lod.* 
				FROM temp_utest_lod  ;

				
			--checking rc_OrderByQuadTreeL
				--adding a column : sel
				ALTER TABLE temp_utest_lod ADD COLUMN sel int ;
				 

				WITH ord AS (
					SELECT ar[1] as oid, ar[2] as ord
					FROM public.rc_OrderByQuadTreeL( 'temp_utest_lod', 0,5,0,-4,32,24) AS ar 
					)
				UPDATE temp_utest_lod SET (sel) = (0 )
				FROM ord
				WHERE  ord.oid = temp_utest_lod.oid;
				WITH ord AS (
					SELECT ar[1] as oid, ar[2] as ord
					FROM public.rc_OrderByQuadTreeL( 'temp_utest_lod', 1,5,0,-4,32,24) AS ar 
					)
				UPDATE temp_utest_lod SET (sel) = (1 )
				FROM ord
				WHERE  ord.oid = temp_utest_lod.oid;
				WITH ord AS (
					SELECT ar[1] as oid, ar[2] as ord
					FROM public.rc_OrderByQuadTreeL( 'temp_utest_lod', 2,5,0,-4,32,24) AS ar 
					)
				UPDATE temp_utest_lod SET (sel) = (2 )
				FROM ord
				WHERE  ord.oid = temp_utest_lod.oid;
				WITH ord AS (
					SELECT ar[1] as oid, ar[2] as ord
					FROM public.rc_OrderByQuadTreeL( 'temp_utest_lod', 3,5,0,-4,32,24) AS ar 
					)
				UPDATE temp_utest_lod SET (sel) = (3 )
				FROM ord
				WHERE  ord.oid = temp_utest_lod.oid;

				 
			

			