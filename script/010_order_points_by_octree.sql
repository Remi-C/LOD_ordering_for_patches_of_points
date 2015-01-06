---------------------------------------------
--Copyright Remi-C  15/02/2014
--
--
--This script expects a postgres >= 9.3, Postgis >= 2.0.2 , pointcloud
--
--
--------------------------------------------

----------Abstract-------------------
--
--This script has function to order a pointcloud following the points closest to the center of octree cells
--
--------------------------------------



-------------------------------
--Ordering points by an octree approach
--
--Given a lcoalized point cloud, we propose a way to order the points based on their  XYZ coordinnates, following an octree approach, 
--where we try to  have for each level a uniform repartition in space of ordered points.
--That is , for each level of an octree, we keep a point per cell whih is the closest to the center of the cell.
--
--
--inside a level points are ordered randomly (more intelligent ordering may be preferable, like a defined pattern which gives some assurance about distribution)
--We could use a Z curb ordering and inverting (read right to left) the binary representation. 
--
--This is achieved with several function, with the top function being public.rc_OrderByOcTree( pointsTable regclass, tot_tree_level INT,OUT result_per_level int[]);
--
--and an intermediate function being public.rc_OrderByOcTreeL( pointsTable text,  tree_level INT, tot_tree_level INT);
--
--this function will return oid of points with an int giving the order for all asked level + the number of points found per level. 
-- All levels will be computed except if a level has less points than the preceding level
--
--	this function expects a table with         | oid::int | x::float | y::float | z::float | ord | level
--
------------
--How does it works?
------
--	for a given tree level, we are going to compute x_bf and y_bf and z_bf, meaning x_binary_full. This are x  (y,z) translated by -min_x (-min_y, -min_z), scaled by (max_x-min_x)2^tree_depth.
--	this means x_bf (y_bf, z_bf) are, when considering binary representation , the path allong a perfect Octree covering ((min_x,min_y,min_z),(max_x,max_y,max_z). 
--	For instance, x_bf = B'0110' means the first LOD is the bottom square, the second LOD the upper square, the third LOD the bottom square, the 4th LOD the upper square.
--	doing the same think for y_bf, and z_bf we get the localisation of the points for each  Octree level.
--
--
--
--For a given L level, we can compute the localisation of the point simply by shifting the binary number to the right by L, then to the left by L. 
--	this is x_bl for x_ binary_level
--	Example  : x = B'10011101', L=3 x_bl = B'10011000', this amount to truncate the L last binary digits. In the decimal world, it amounts to something like 
--	 x_l = x_f - x_f%(2^L), where % is the modulo and ^ the power. 
--
--finally, we compute x_bm and y_bm and z_bm, for x_binary_middle.
--	this is the coordinate of the middle point of the square for a given point and a given level.
--	per construction, this is the target point, ie, we would like, for each level, to find real points as close as possible to this target points.
--	There are 2^L middle points per level (1 per square)
--	The formula to compute the middle points is : 
--		x_bm :=x_bl + 2^(tot_tree_level-tree_level-1) , with tot_tree_level being the total depth of quad tree, and tree_level being the current depth of quad tree.
--
--We want to find the points closest to target points. For all the points in point cloud, we compute the distance between the x_bf,y_bf and the middle point x_bm,y_bm.
--	This distance is computed using the square norme distance, that is
--	GREATEST(@(x_bm-x_bf),@(y_bm-y_bf) );, where @ is the absolute value. 
--	This norm is ideal for what we want because all points in the miniml square (max level) will have the same distance to a point. 
--	This is very coherent with the idea of the algorithm and avoid rounding issues, as well as allow fast computation.
--	Of course the distance computing is only done for the points in the cell, points outside cannot be candidate.
--
--In the implementation all these computing are united in one function
--
--Then we select the closest point based on that distance. For this we tried 2 methods :
--	first one is using windows function that, for each line, give the oid of the closest point within a square. Then we group by this oid.
--	the other option is to use a custom aggregates : we group by square, then for each group, 
--	we return one line with the oid of the min distance to middle point of this square, or nothing if no points.
--
--
--We have now the points closest to middle points for each square, or nothing when the square is empty. 
--Now we order the points following either a custom order (reverse(x_bf), Z curve space curve with smart modulo game), or a random order.
--
------------------------------
--List of function and dependency
--
--
--	(ni another file)SELECT public.rc_AddColIfNotExist( 'public.kat', 'pfad1', 'int');
--
------------------------------
--@TODO  : improvements :
--the current version is slow (6.5 sec for a level for 100k points).
--we could ptotentially divide computing time by 3 for a level, and gain a lot for multi-level computing (storing x_bf,y_bf)
--
--Here are the suggested test for improvments
--
--	Ideally,  function computing the "x_b*" and "distance" would be written in C or a fast procedural langage.
--
--	the min table computing is slow, all the min/max are computed separatly, we could compute it in the same custom aggregate function, so as to reduce the computing time.
--	the min computing takes about 10% of the total time.
--	--note : tried with a custom aggregate plpgsql function : slower. Would need a custom aggreegate C function !
--
--	There may be interest in using indexes.
--	
--	In the perspective of computing all the level each time (and not juste one), the computing of x_bf, y_bf should be separate and stored in columns in the table so as to be reused.
--	There is no point in comuting x_bf,y_bf L time (L being the choosen depth of the quad tree).
--
--
------------------------------

SET search_path to lod, public ;

	DROP FUNCTION IF EXISTS public.rc_OrderByOcTree( pointsTable regclass, tot_tree_level INT,OUT result_per_level int[]);
		CREATE OR REPLACE FUNCTION public.rc_OrderByOcTree( pointsTable regclass, tot_tree_level INT, OUT result_per_level int[])
		 AS
		$BODY$
		--this function computes quad tree order for points.
		--It expects as input 
			--a table with a column oid of type to be cast to int with unique id, a column x of type to be cast to  numeric, a column y of type to be cast to numeric,
			--we add a column x_bf, y_bf, lev and ord
			--a column x_bf_L and y_bf_L double precision where L is the max tree depth, filled with ( x-min_x)*2^%s / (max_x-min_x) 
		DECLARE
		_q text :='';
		_pts_nb_in_current_level BIGINT;
		_end_indice int := 0;
		_tot_points numeric;
		_max_num_points_in_next_level BIGINT;
		BEGIN

			--creating the column with x_bf and y_bf which will be used for computation by each level
			PERFORM rc_CreatePbfColumn3D(pointsTable, tot_tree_level);
			--emptying column if previous classing
			PERFORM format('UPDATE %I SET (lev,ord) = (NULL,NULL)',pointsTable);

			EXECUTE  format('SELECT count(*) FROM %I',pointsTable) INTO _tot_points;
			--RAISE NOTICE '_tot_points %',_tot_points;
			--added for robustness : we stop if only one point : no need to order it! 
			IF _tot_points IS NULL OR _tot_points=1 or _tot_points=0 THEN
				RETURN ;
			END IF;
			--loop on all level, we escape if the level becomes empty (few points in patch and/or too much level)
			--or if the number of points in the level is less than number of points in previous level

			FOR i in 0..tot_tree_level
			LOOP
			--	RAISE NOTICE 'loop, %',i;

				--how many points remains : if too few, stopping the computing.
				EXECUTE format('
				SELECT count(*) 
				FROM %I
				WHERE lev>=%s OR lev IS NULL;
				',pointsTable,i) INTO _max_num_points_in_next_level;
			--	RAISE NOTICE 'points remaining : %, level : %',_max_num_points_in_next_level,i;

				IF _max_num_points_in_next_level <power(2, i-1) THEN
					--no need to compute : there won't be enough points in the next level
					EXIT;
				END IF;

				--computing the ordering for the current tree level 
				_q := format('
					WITH the_order AS (
						SELECT  public.rc_OrderByOcTreeL( pointsTable:=''%I'',tree_level:=%s,tot_tree_level:=%s) ordering_result
					)
					,total_result AS (
						SELECT  (t_o.ordering_result)[1] AS order_oid, (t_o.ordering_result)[2] AS ord
						FROM  the_order t_o ),
					the_update AS (	
						UPDATE %I pt SET (lev, ord) = (%s, tr.ord)
						FROM total_result tr
						WHERE pt.oid = tr.order_oid
						AND (pt.lev >= %s OR pt.lev IS NULL)
						RETURNING lev
					) 
					SELECT count(*)
					FROM the_update; 
				',pointsTable,i,tot_tree_level,pointsTable,i,i);

				IF i!=0 AND abs(_tot_points-result_per_level[i])<result_per_level[i] THEN 
					--no need to compute next level, there won't be enough points in it, stopping.
					EXIT;
				END IF;
			
				EXECUTE _q INTO _pts_nb_in_current_level;

			
				--stopping in no points where ordered (not enough point and/or we went too deep in the tree)
				IF _pts_nb_in_current_level  IS NULL  OR _pts_nb_in_current_level =0 OR (i !=0 AND _pts_nb_in_current_level<result_per_level[i])THEN
					-- exiting the loop, furthe rlevel are going ot be empty
			--		raise notice 'existing the loop for i=%',i;
					_end_indice := i;
					EXIT ;
				END IF;

					result_per_level[i+1]:=_pts_nb_in_current_level;
				--_pts_nb_in_current_level := 
			END LOOP; -- loop on all tree level

			--EXECUTE format('UPDATE %I SET (lev,ord) = (NULL,NULL) WHERE lev= %s',pointsTable,_end_indice);
			
			ReTURN ;
			
			
		return;
		END;
		$BODY$
		LANGUAGE plpgsql STRICT VOLATILE;

		--SELECT    public.rc_OrderByOcTree( 'test_order_index_points'::regclass , 12);
		--SELECT *
		--FROM test_order_index_points
		--oRDER BY lev DESC 



		--creating computing function :
			DROP FUNCTION IF EXISTS public.rc_OrderByOcTreeL( pointsTable regclass,  tree_level INT, tot_tree_level INT);
			CREATE OR REPLACE FUNCTION public.rc_OrderByOcTreeL( pointsTable regclass,  tree_level INT, tot_tree_level INT)
			RETURNS  SETOF int[] AS
			$BODY$
			--this function computes quad tree order for points.
			--It expects as input 
			--a table with a column oid of type to be cast to int with unique id, a column x of type to be cast to  numeric, a column y of type to be cast to numeric,
			--a column level with the level of the point
			--a column x_bf_L and y_bf_L and z_bf_L double precision where L is the max tree depth, filled with ( x-min_x)*2^%s / (max_x-min_x) 
			DECLARE
			_q text :='';
			BEGIN
				_q := format('
					WITH points AS (
					SELECT oid::int, x::double precision, y::double precision , z::double precision, x_bf_%s, y_bf_%s, z_bf_%s
					FROM %I 
					WHERE lev >= %s OR lev IS NULL),
					quad_tree_level AS (
						SELECT %s as tot_level, %s AS current_level LIMIT 1
					)',tot_tree_level,tot_tree_level,tot_tree_level,pointsTable,tree_level,tot_tree_level, tree_level);

				_q := _q || format('
					,
					prep_for_comp AS (
						SELECT
						oid
						,rc_P3D(x, y,z, qtl.current_level,qtl.tot_level ,x_bf_%s,y_bf_%s,z_bf_%s) f
						FROM points,  quad_tree_level AS qtl 
					)',tot_tree_level,tot_tree_level,tot_tree_level,tot_tree_level,tot_tree_level);

				_q := _q || format('
					, selected AS (
						SELECT
							--first_value(oid) OVER (PARTITION BY (f).x_bl, (f).y_bl, (f).z_bl ORDER BY (f).distance ASC, oid ASC) AS selected_id
							--(rc_FindClosestPoint(ARRAY[oid::int,(f).distance]))[1] AS selected_id 
							first(oid ORDER BY (f).distance ASC, oid ASC )   AS selected_id
						FROM prep_for_comp, quad_tree_level AS qtl
						GROUP BY (f).x_bl::bit(%s), (f).y_bl::bit(%s), (f).z_bl::bit(%s)
					)
					SELECT
						ARRAY[selected_id::int, row_number() over (ORDER BY ( random()  ) )::int] AS oid_order
						--note : the ordering should be a Z-curve (morton) read Right from left
						--ARRAY[selected_id::int, row_number() over (ORDER BY (pfc.x_bf::int + pfc.y_bf::int),(pfc.x_bf::int - pfc.y_bf::int) )::int] AS oid_order
						--ARRAY[selected_id::int, row_number() over (ORDER BY reverse(pfc.x_bf::text)::int + reverse(pfc.y_bf::text)::int,pfc.x_bf , pfc.y_bf )::int] AS oid_order
					FROM selected gi LEFT JOIN prep_for_comp pfc ON (gi.selected_id = pfc.oid)
					',tot_tree_level,tot_tree_level,tot_tree_level); 
					--raise notice '%',_q;
					RETURN QUERY EXECUTE _q;
					RETURN;  
			--	RAISE NOTICE 'the querry 
			--	%',_q;	 
				return;
			END;
			$BODY$
			  LANGUAGE plpgsql STRICT IMMUTABLE;


			--testing_lod_2
			--DROP TABLE IF EXISTS public.test_order_index_result;
			--CREATE table public.test_order_index_result AS
			--	SELECT f.oid[1],f.oid[2] ord , toip.noisy_point, toip.geom
			--	FROM public.rc_OrderByQuadTreeL( pointsTable:='test_order_index_points',tree_level:=6,tot_tree_level:=6) f(oid)
			--	LEFT OUTER JOIN test_order_index_points toip ON (toip.oid= f.oid[1])

				--sur 100k points
				--sans rien : 3.2sec
					--les min : 5.3sec
					--les pbf : 11sec
					--les pbl : 15.6
					--les pbm : 20.1
					--distance : 23.9
					--avec le calcul : 27.5
					--avedc le groupe by : 28.8
					--avec ordering : 30 sec

					



		
		
		--testing ordering function on data

		--create table with result





DROP FUNCTION IF EXISTS public.rc_CreatePbfColumn3D(points_table regclass, tot_tree_level INT,OUT columns_added BOOLEAN);
CREATE OR REPLACE FUNCTION public.rc_CreatePbfColumn3D(points_table regclass, tot_tree_level INT, OUT columns_added BOOLEAN)
AS
$BODY$
--utility function for computing quad tree order
--this function creates 4 columns x_bf_N and y_bf_N (N = tree depth) with indexes on a given table if they don't exists
--also another column 'lev' to store the level of ordering, and a column 'ord' to store the order in a level.
--x_b and y_bf are computed based on value of x and y and tot_tree_level following the formula : 
DECLARE
_q text;
BEGIN
	--creating columns in the given table if they don't exist
	
	columns_added := public.rc_AddColIfNotExist( points_table,
			format('x_bf_%s',tot_tree_level)
			,'int') 
		AND  public.rc_AddColIfNotExist( points_table,
			format('y_bf_%s',tot_tree_level)
			,'int') 
		AND  public.rc_AddColIfNotExist( points_table,
			format('z_bf_%s',tot_tree_level)
			,'int') 
		AND  public.rc_AddColIfNotExist( points_table,'lev'::text, 'int')
		AND  public.rc_AddColIfNotExist( points_table,'ord'::text, 'int');

	--computing values
	_q := format('
		WITH min AS (
			SELECT min(x) min_x, min(y) AS min_y, min(z) AS min_z , max(x) AS max_x, max(y) AS max_y, max(z) AS max_z
			FROM %I
		)
	UPDATE %I SET 
		x_bf_%s =  (     ( x-min_x)*2^%s / CASE  (max_x-min_x) WHEN 0 THEN 1 ELSE  (max_x-min_x) END      )::int 
		, y_bf_%s = (     ( y-min_y)*2^%s /CASE  (max_y-min_y) WHEN 0 THEN 1 ELSE  (max_y-min_y) END   )::int 
		,z_bf_%s = (     ( z-min_z)*2^%s /CASE  (max_z-min_z) WHEN 0 THEN 1 ELSE  (max_z-min_z) END  )::int
		,x = x*2^%s
		,y = y*2^%s
		,z = z*2^%s
		FROM min;'
		,points_table,points_table,tot_tree_level,tot_tree_level,tot_tree_level,tot_tree_level,tot_tree_level,tot_tree_level,tot_tree_level,tot_tree_level,tot_tree_level
		);
	--dafulat behavior : if column already exist, update x_bf and y_bf value
	EXECUTE _q;

	--creating indexes on columns, only when we just added the columns. Else we expect the indexes to already exist
	--IF(columns_added=TRUE) THEN
		--NOTE : not adding indexes for the moment as it would be difficult to evaluate which type of index may help.
	--END IF;

	RETURN ;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;


		
	--SELECT rc_CreatePbfColumn3D('public.test_order_index_points', 6);



DROP FUNCTION IF EXISTS public.rc_P3D(x DOUBLE PRECISION, y DOUBLE PRECISION,z DOUBLE PRECISION,tree_level INT, tot_tree_level INT, x_bf int,  y_bf int,  z_bf int,OUT x_bl INT, OUT y_bl INT, OUT z_bl INT, 
--OUT x_bm INT, OUT y_bm INT, 
OUT distance INT);
CREATE OR REPLACE FUNCTION public.rc_P3D(x DOUBLE PRECISION, y DOUBLE PRECISION, z DOUBLE PRECISION,tree_level INT, tot_tree_level INT, x_bf int,  y_bf int,  z_bf int,OUT x_bl INT, OUT y_bl INT, OUT z_bl INT, 
--OUT x_bm INT, OUT y_bm INT, 
OUT distance INT)
AS
$BODY$
--function giving the maximim length bit representation of points
DECLARE
x_bm int;
y_bm int;
z_bm INT;
BEGIN
	--x_bf :=(          ( x-min_x)*2^tot_tree_level / (max_x-min_x)      )::int;
	--y_bf :=(          ( y-min_y)*2^tot_tree_level / (max_y-min_y)      )::int;

	x_bl := x_bf - x_bf%(2^(tot_tree_level-tree_level))::int;
	y_bl := y_bf - y_bf%(2^(tot_tree_level-tree_level))::int;
	z_bl := z_bf - z_bf%(2^(tot_tree_level-tree_level))::int;

	
	x_bm :=CASE WHEN ( x_bl + 2^(tot_tree_level-tree_level-1))::int > 2^tot_tree_level 
		THEN ( x_bl - 2^(tot_tree_level-tree_level-1))::int 
		ELSE  ( x_bl + 2^(tot_tree_level-tree_level-1))::int END ;
	y_bm :=CASE WHEN ( y_bl + 2^(tot_tree_level-tree_level-1))::int > 2^tot_tree_level 
		THEN ( y_bl - 2^(tot_tree_level-tree_level-1))::int 
		ELSE  ( y_bl + 2^(tot_tree_level-tree_level-1))::int END ;
	z_bm :=CASE WHEN ( z_bl + 2^(tot_tree_level-tree_level-1))::int > 2^tot_tree_level 
		THEN ( z_bl - 2^(tot_tree_level-tree_level-1))::int 
		ELSE  ( z_bl + 2^(tot_tree_level-tree_level-1))::int END ; 
	
	--distance := GREATEST(@(x_bf-x_bm),@(y_bf-y_bm),@(z_bf-z_bm) );
	distance := sqrt( (x-x_bm)^2+(y-y_bm)^2+(z-z_bm)^2 )::int;
	
	RETURN;	
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;



