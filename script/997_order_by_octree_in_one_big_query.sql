--------------
-- Remi cura thales ign 11/2014
--------------
--this script tries to order in octree in one querry
--------------

SET search_path to lod, public; 

DROP TABLE IF EXISTS test_order_index_points;
	CREATE table test_order_index_points AS
	WITH generated_points AS (
		SELECT row_number() over() AS oid
			,( x+0.5 - random()*2*110/1000 )/16.0  AS x
			,( y+0.5 - random()*2*110/1000  )/16.0  AS y
			--,50+0.5 AS z--  
			,( z+0.5 - random()*2*110/1000 )/16.0  AS z
		FROM generate_series(1,16) AS x, generate_series(1,16) AS y ,generate_series(1,16) AS z
			
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
		FROM generated_points,min_max
		WHERE  z<=2/16.0;


SELECT *
FROM test_order_index_points
LIMIT 100;

--passing all value to int by sampling on a 2^7 voxel grid
UPDATE test_order_index_points SET (x,y,z) = ((x*2^7)::int, (y*2^7)::int,(z*2^7)::int);

COPY 
		( SELECT x,y ,z, oid  
		FROM test_order_index_points  
		)
	TO '/media/sf_E_RemiCura/DATA/test_order_index_points_one_query.csv'-- '/tmp/temp_pointcloud_lod.csv'
	WITH csv header;

--grouping by the level , taking the closest to mid of level
WITH lev AS (
	SELECT 2 AS cur_lev, 7 as tot_lev 
	LIMIT 1
)
--,coor_lev AS (
	SELECT toi.*,  (x/(2^(tot_lev-cur_lev)))::int AS x_lev, (y/(2^(tot_lev-cur_lev)))::int AS y_lev, (z/(2^(tot_lev-cur_lev)))::int AS z_lev 
	FROM lev, test_order_index_points as toi 
)
SELECT x,y,z, x_lev+ 2^(cur_lev-1) AS x_o,  y_lev+ 2^(cur_lev-1) AS y_o,  z_lev+ 2^(cur_lev-1) AS z_o
FROM lev, coor_lev
--GROUP BY  (x/(2^(tot_lev-cur_lev)))::int AS x_lev, (y/(2^(tot_lev-cur_lev)))::int AS y_lev, (z/(2^(tot_lev-cur_lev)))::int AS z_lev
LIMIT 100



COPY  (
WITH lev AS (
	SELECT 4 AS cur_lev, 7 as tot_lev 
	LIMIT 1
) 
,agg  AS (
SELECT 
	rc_find_middle(
		(x,y,z,  x_o  , y_o , z_o ,oid)::rc_middle_type ) AS r 
FROM lev, test_order_index_points , rc_compute_centers(x::int,y::int,z::int,cur_lev,tot_lev) 
GROUP BY x_o,y_o,z_o
)
SELECT (r).curr_mid_value_x, (r).curr_mid_value_y, (r).curr_mid_value_z, (r).cur_mid_oid
FROM agg  
)TO '/media/sf_E_RemiCura/DATA/test_order_index_points_one_query.csv'- 
WITH csv header;


WITH point AS (
	 SELECT x,y ,z, oid  
	FROM test_order_index_points  
)
SELECT  rc_order_octree_lev(  5,7 )
FROM point



DROP FUNCTION IF EXISTS rc_compute_centers( x int, y int, z int ,   cur_lev int , tot_lev  int ) CASCADE;
	CREATE OR REPLACE FUNCTION rc_compute_centers( x int, y int, z int ,  cur_lev int , tot_lev  int
		, OUT x_o int
		, OUT y_o int
		, OUT z_o int)  
	AS $$ 
	DECLARE 
	BEGIN  
		x_o := CASE WHEN (  (x/(2^(tot_lev-cur_lev)))::int   * 2^(tot_lev-cur_lev) + 2^(tot_lev-cur_lev -1 ) )::int  >2^tot_lev 
			THEN  ((x/(2^(tot_lev-cur_lev)))::int   * 2^(tot_lev-cur_lev) - 2^(tot_lev-cur_lev -1 ) )::int
			ELSE  (  (x/(2^(tot_lev-cur_lev)))::int   * 2^(tot_lev-cur_lev) + 2^(tot_lev-cur_lev -1 ) )::int
			END  ; 
		y_o := CASE WHEN (  (y/(2^(tot_lev-cur_lev)))::int   * 2^(tot_lev-cur_lev) + 2^(tot_lev-cur_lev -1 ) )::int  >2^tot_lev 
			THEN  ((y/(2^(tot_lev-cur_lev)))::int   * 2^(tot_lev-cur_lev) - 2^(tot_lev-cur_lev -1 )  )::int
			ELSE  (  (y/(2^(tot_lev-cur_lev)))::int   * 2^(tot_lev-cur_lev) + 2^(tot_lev-cur_lev -1 ) )::int
			END  ; 
		z_o := CASE WHEN (  (z/(2^(tot_lev-cur_lev)))::int   * 2^(tot_lev-cur_lev) + 2^(tot_lev-cur_lev -1 ) )::int  >2^tot_lev 
		THEN  ((z/(2^(tot_lev-cur_lev)))::int   * 2^(tot_lev-cur_lev) - 2^(tot_lev-cur_lev -1 )  )::int
		ELSE  (  (z/(2^(tot_lev-cur_lev)))::int   * 2^(tot_lev-cur_lev) + 2^(tot_lev-cur_lev -1 ) )::int
		END  ;  
	RETURN;
	END;
$$ LANGUAGE plpgsql IMMUTABLE CALLED ON NULL INPUT ;



DROP TYPE IF EXISTS rc_middle_type CASCADE;
CREATE TYPE rc_middle_type AS
    ( curr_mid_value_x int,curr_mid_value_y int,curr_mid_value_z int
    , cur_mid_dist_x int
	, cur_mid_dist_y int
	, cur_mid_dist_z int
    , cur_mid_oid int ) ; 
 
 
DROP FUNCTION IF EXISTS rc_sfunc_find_middle(  rc_middle_type ,  rc_middle_type) CASCADE;
	CREATE OR REPLACE FUNCTION rc_sfunc_find_middle(internal_state rc_middle_type ,  next_data_values rc_middle_type, OUT next_internal_state rc_middle_type)  
	AS $$ 
	DECLARE 
	old_dist int; 
	new_dist int ;   
	BEGIN 
		
		IF internal_state.cur_mid_dist_x IS NULL
			OR internal_state.cur_mid_dist_y IS NULL
			OR internal_state.cur_mid_dist_z IS NULL
			THEN 
			internal_state.cur_mid_dist_x := next_data_values.cur_mid_dist_x ; 
			internal_state.cur_mid_dist_y := next_data_values.cur_mid_dist_y ; 
			internal_state.cur_mid_dist_z := next_data_values.cur_mid_dist_z ; 
		END IF  ;
	
		IF  internal_state.curr_mid_value_x IS NULL 
			OR  internal_state.curr_mid_value_y IS NULL 
			OR  internal_state.curr_mid_value_z IS NULL 
			OR internal_state.cur_mid_oid IS NULL
		THEN 
			internal_state.curr_mid_value_x = next_data_values.curr_mid_value_x ;
			internal_state.curr_mid_value_y = next_data_values.curr_mid_value_y ;
			internal_state.curr_mid_value_z = next_data_values.curr_mid_value_z ;
			internal_state.cur_mid_oid = next_data_values.cur_mid_oid ;  
		END IF ; 
		
		next_internal_state = internal_state ; 
		old_dist :=  
			 abs(internal_state.cur_mid_dist_x - internal_state.curr_mid_value_x)
			 + abs(internal_state.cur_mid_dist_y - internal_state.curr_mid_value_y)
			 + abs(internal_state.cur_mid_dist_z - internal_state.curr_mid_value_z) ;
		new_dist :=abs(internal_state.cur_mid_dist_x - next_data_values.curr_mid_value_x)
			 + abs(internal_state.cur_mid_dist_y - next_data_values.curr_mid_value_y)
			 + abs(internal_state.cur_mid_dist_z - next_data_values.curr_mid_value_z) ; 
		IF 	new_dist
				<= old_dist 
		THEN 
		--RAISE NOTICE 'toto';
			next_internal_state.curr_mid_value_x =  next_data_values.curr_mid_value_x ;--new_dist ; 
			next_internal_state.curr_mid_value_y=  next_data_values.curr_mid_value_y ;--new_dist ; 
			next_internal_state.curr_mid_value_z =  next_data_values.curr_mid_value_z ;--new_dist ; 
			next_internal_state.cur_mid_oid = next_data_values.cur_mid_oid ;  
		END IF ; 

		--RAISE NOTICE 'input : % , %, output : %',internal_state,next_data_values,  next_internal_state ; 
	RETURN;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE CALLED ON NULL INPUT;


	
DROP FUNCTION IF EXISTS rc_ffunc_find_middle(  rc_middle_type  ) CASCADE;
	CREATE OR REPLACE FUNCTION rc_ffunc_find_middle( internal_state rc_middle_type , OUT middle  rc_middle_type)  
	AS $$ 
	DECLARE 
	BEGIN 
		middle :=internal_state; 
	RETURN;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE CALLED ON NULL INPUT ;

 

DROP AGGREGATE IF EXISTS rc_find_middle(rc_middle_type) ;
CREATE AGGREGATE rc_find_middle (rc_middle_type) (
    SFUNC = rc_sfunc_find_middle ,
    STYPE = rc_middle_type ,
    FINALFUNC  = rc_ffunc_find_middle
);


SELECT rc_find_middle(( s,s,s,4,4,4,s )::rc_middle_type)
FROM generate_series(1,20) AS s;




SELECT gid
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p 
		WHERE p.gid >100000
		AND pc_numpoints(patch) BETWEEN 1000 AND 10000
		LIMIT 10




COPY  (  
	WITH pt AS (
		SELECT row_number() over() as oid, pc_get(pt,'x')AS x, pc_get(pt,'y') as y, pc_get(pt,'z') as z, pt
		FROM acquisition_tmob_012013.riegl_pcpatch_space as p
			,pc_explode(patch) as pt
		WHERE p.gid =405028
	) 
	, min_max AS (
		SELECT   
			  min(x)/2+max(x)/2  AS x_min
			, min(y)/2+max(y)/2  AS y_min
			, min(z)/2+max(z)/2  AS z_min
			,greatest(max(x) - min(x),max(y) - min(y),max(z) - min(z)) AS max_r 
		FROM pt 
		LIMIT 1 
	)	 
		SELECT 
			 ((( x - x_min) / max_r +0.5) * 2^7 )::int as x
			, ((( y - y_min) / max_r +0.5) * 2^7)::int as y
			,( (( z - z_min) / max_r +0.5) * 2^7)::int as z 
			,oid
		FROM min_max, pt
)TO '/media/sf_E_RemiCura/DATA/test_order_octree_patch_405028.csv'-- '/tmp/temp_pointcloud_lod.csv'
WITH csv header;


COPY  (  
WITH pt AS (
	SELECT row_number() over() as oid, pc_get(pt,'x')AS x, pc_get(pt,'y') as y, pc_get(pt,'z') as z, pt
	FROM acquisition_tmob_012013.riegl_pcpatch_space as p
		,pc_explode(patch) as pt
	WHERE p.gid =405028
) 
, min_max AS (
			SELECT   
				  min(x)/2+max(x)/2  AS x_min
				, min(y)/2+max(y)/2  AS y_min
				, min(z)/2+max(z)/2  AS z_min
				,greatest(max(x) - min(x),max(y) - min(y),max(z) - min(z)) AS max_r 
			FROM pt 
			LIMIT 1 
		)	
		
,point AS (
	SELECT 
		oid
		, ((( x - x_min) / max_r +0.5) * 2^7 )::int as x
		, ((( y - y_min) / max_r +0.5) * 2^7)::int as y
		,( (( z - z_min) / max_r +0.5) * 2^7)::int as z 
	FROM min_max, pt
)
  ,agg_4  AS (
	SELECT 
		rc_find_middle( (pt.x ,pt.y ,pt.z,  x_o  , y_o , z_o ,pt.oid)::rc_middle_type ) AS r 
	FROM point as pt, rc_compute_centers(pt.x::int,pt.y::int,pt.z::int,0,7) 
	GROUP BY x_o,y_o,z_o
)
SELECT (r).curr_mid_value_x AS x, (r).curr_mid_value_y AS y , (r).curr_mid_value_z AS z, (r).cur_mid_oid AS oid, 4 AS cur_lev
FROM agg_4  
)TO '/media/sf_E_RemiCura/DATA/test_order_octree_patch_405028_level_0.csv'-- '/tmp/temp_pointcloud_lod.csv'
WITH csv header;


SELECT r.*  
FROM acquisition_tmob_012013.riegl_pcpatch_space as p ,rc_order_octree(patch,7)  AS r
WHERE p.gid =405028


DROP FUNCTION IF EXISTS rc_order_octree( ipatch PCPATCH, tot_lev   int[] ) ;
	CREATE OR REPLACE FUNCTION rc_order_octree( ipatch PCPATCH, tot_lev   int , OUT opatch PCPATCH, OUT points_per_level INT[])
	
	AS $$ 
	DECLARE 
		q text:='';
		i int :=0; 
	BEGIN  -- explanation : scale to normal scale, offset of hlaf grid step, modulo to put everything inside the grid
		q := format(' 
			WITH pt AS (
				SELECT row_number() over() as oid, pc_get(pt,''x'')AS x, pc_get(pt,''y'') as y, pc_get(pt,''z'') as z, pt
				FROM pc_explode($1) as pt  
			) 
			, min_max AS (
				SELECT   
					  min(x)/2+max(x)/2  AS x_min
					, min(y)/2+max(y)/2  AS y_min
					, min(z)/2+max(z)/2  AS z_min
					,greatest(max(x) - min(x),max(y) - min(y),max(z) - min(z)) AS max_r 
				FROM pt 
				LIMIT 1 
			)	 	
			,point AS (
				SELECT 
					oid
					, ((( x - x_min) / CASE WHEN max_r = 0 THEN 1 ELSE max_r END  +0.5) * 2^%s )::int as x
					, ((( y - y_min) / CASE WHEN max_r = 0 THEN 1 ELSE max_r END  +0.5) * 2^%s )::int as y
					,( (( z - z_min) / CASE WHEN max_r = 0 THEN 1 ELSE max_r END  +0.5) * 2^%s )::int as z 
				FROM min_max, pt
			)
			
		', tot_lev ,tot_lev, tot_lev  ); 
		FOR i in 0..tot_lev
		LOOP
			--if(i !=0 )
			--THEN q := q || ' UNION ALL' ;  END IF;
			
			q := q || rc_order_octree_lev( i, tot_lev) ; 
		END LOOP; 
		q := q ||' 
		,ordering AS (
		SELECT DISTINCT ON (oid) oid, cur_lev
		FROM ( ' ; 
		FOR i in 0..tot_lev
		LOOP
			q := q ||format( ' SELECT oid, cur_lev FROM agg_%s WHERE cur_lev IS NOT NULL AND oid IS NOT NULL',i); 
			if(i !=tot_lev )
			THEN q := q || ' UNION ALL' ;  
			END IF; 
		END LOOP; 

		q:=q ||
		') as sub
		ORDER BY oid, cur_lev ASC NULLS LAST  )

		 ,count_per_lev AS (
			SELECT array_agg(nb_per_level ORDER BY cur_lev ASC) AS points_per_level 
			FROM (
				SELECT count(*) AS nb_per_level, cur_lev
				FROM ordering
				GROUP BY cur_lev 
				) as sub
			LIMIT 1 
		) 
		SELECT opatch , points_per_level 
			FROM (
			SELECT pc_patch(pt ORDER BY cur_lev NULLS LAST, random()) as opatch
			FROM pt
				LEFT OUTER JOIN ordering on (pt.oid = ordering.oid)
				)AS sub , 
				  count_per_lev  ; ' ;
		
		EXECUTE q USING ipatch INTO opatch, points_per_level ; 
		--raise notice '%',q; 
		 RETURN   ;
	END;
$$ LANGUAGE plpgsql IMMUTABLE CALLED ON NULL INPUT ;

		
DROP FUNCTION IF EXISTS rc_order_octree_lev(   cur_lev  int , tot_lev   int ) CASCADE;
	CREATE OR REPLACE FUNCTION rc_order_octree_lev(   cur_lev  int , tot_lev   int, out q text  ) 
	AS $$ 
	DECLARE 
	BEGIN  -- explanation : scale to normal scale, offset of hlaf grid step, modulo to put everything inside the grid

		
		q := format(' 
		, agg_%s AS (
			SELECT (r).curr_mid_value_x AS x, (r).curr_mid_value_y AS y , (r).curr_mid_value_z AS z, (r).cur_mid_oid AS oid, %s AS cur_lev
			FROM   (
			SELECT ' , cur_lev, cur_lev); 
			IF cur_lev != 0 THEN 
			q := q ||
			format('CASE WHEN (1 --SELECT count(*) FROM agg_%s LIMIT 1
			  ) < pow(4,%s) THEN  (NULL,NULL, NULL, NULL, NULL,NULL,NULL)::rc_middle_type ELSE 
				rc_find_middle( (pt.x ,pt.y ,pt.z,  x_o  , y_o , z_o ,pt.oid)::rc_middle_type ) END ', cur_lev-1, cur_lev-2 );
			ELSE q := q 
			|| 'rc_find_middle( (pt.x ,pt.y ,pt.z,  x_o  , y_o , z_o ,pt.oid)::rc_middle_type ) ' ; 
			END IF ;
			q := q ||format(	' AS r 
			FROM point as pt, rc_compute_centers(pt.x::int,pt.y::int,pt.z::int,%s,%s) 
			GROUP BY x_o,y_o,z_o ) as sub
		)   ', cur_lev, tot_lev); 
		 RETURN  ;
	END;
$$ LANGUAGE plpgsql IMMUTABLE CALLED ON NULL INPUT ;

 SELECT rc_order_octree_lev(4,7) ;


