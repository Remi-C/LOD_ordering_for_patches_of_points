---------------------------------------------
--Copyright Remi-C  22/10/2013
--
--
--This script expects a postgres >= 9.3, Postgis >= 2.0.2, postgis topology enabled
--
--This is a support scvript with old/test functions
--------------------------------------------



  


DROP FUNCTION IF EXISTS public.rc_Pbf(x numeric, y numeric, tot_tree_level INT,x_min numeric, x_max numeric, y_min numeric ,y_max numeric, OUT x_bf int, OUT y_bf int );
CREATE OR REPLACE FUNCTION public.rc_Pbf(x numeric, y numeric, tot_tree_level INT,min_x numeric, max_x numeric, min_y numeric, max_y numeric, OUT x_bf int
	, OUT y_bf int)
AS
$BODY$
--function giving the maximim length bit representation of points
DECLARE
_the_query text;
_the_result record;
BEGIN
	x_bf :=(     ( x-min_x)*2^tot_tree_level / (max_x-min_x)       )::int;
	y_bf :=(     ( y-min_y)*2^tot_tree_level / (max_y-min_y)       )::int;

	RETURN;	
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;




DROP FUNCTION IF EXISTS public.rc_Pbm(x int, y INT,  tot_tree_level INT, OUT x_bf int, OUT y_bf int );
CREATE OR REPLACE FUNCTION public.rc_Pbm(x_bl int, y_bl INT,  tree_level INT, tot_tree_level INT, OUT x_bm int, OUT y_bm int )
AS
$BODY$
--function giving the middle point given a certain level of detail and 2 intervals (x, y)
DECLARE
_the_query text;
_the_result record;
BEGIN
	--note : this is  int based computing, it would be preferable to do binary based computing, that is x_bm = x_bl + B'0X000', but binary+binary doesn't exists in postgres
	x_bm :=( x_bl + 2^(tot_tree_level-tree_level-1))::int;
	y_bm :=( y_bl + 2^(tot_tree_level-tree_level-1))::int;
	RETURN;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
	SELECT x_bm::bit(6), y_bm::bit(6)
	FROM rc_Pbm(B'01110'::int,B'00010'::int,5,6);




DROP FUNCTION IF EXISTS public.rc_Pbl(x_bf int, y INT,  tot_tree_level INT, OUT x_bf int, OUT y_bf int );
CREATE OR REPLACE FUNCTION public.rc_Pbl(x_bf int, y_bf INT,  tree_level INT, tot_tree_level INT, OUT x_bl int, OUT y_bl int )
AS
$BODY$
--function giving the correct interval computed from x_bf, y_bf at the desired level of detail
DECLARE
_the_query text;
_the_result record;
BEGIN
	--note : this is a version with int computing, where it should be based on binary, but plpgsql binary operations are slow. 
	--If implementing in C , binary version should be faster.
	
	x_bl := x_bf - x_bf%(2^(tot_tree_level-tree_level))::int;
	y_bl := y_bf -y_bf%(2^(tot_tree_level-tree_level))::int;
	--x_bl := (x_bf >>(tot_tree_level-tree_level))<<(tot_tree_level-tree_level);
	--y_bl := (y_bf >>(tot_tree_level-tree_level))<<(tot_tree_level-tree_level);
	RETURN;
	
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
	SELECT x_bl::bit(6), y_bl::bit(6)
	FROM rc_Pbl(B'111111'::int,B'000110'::int,0,6);




SELECT ('101001000100001'::bit(15) )::bit(3)


--function to compute a square norm distance if < a_range, else 0
DROP FUNCTION IF EXISTS public.rc_distancePPfixe(x int ,y int, xf int, yf int);
CREATE OR REPLACE FUNCTION public.rc_distancePPfixe(x int ,y int, xm int, ym int)
RETURNS int AS
$BODY$
DECLARE
_temp int;
BEGIN
	--using square norm
	--Note: this should be binary based computation, but plpgsql binary is slow, and binary-binary is not defined
	--if implementing in c it should be faster to use a binary using version.
	
	RETURN GREATEST(@(xm-x),@(ym-y) );
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;

SELECT rc_distancePPfixe(3,5,2,6);





DROP FUNCTION IF EXISTS public.rc_MSB(the_bit_string anyelement, to_keep int);
CREATE OR REPLACE FUNCTION public.rc_MSB(the_bit_string anyelement, to_keep int)
RETURNS anyelement AS
$BODY$
DECLARE
_the_query text;
_the_result record;
BEGIN
	_the_query := format('SELECT ''%s''::bit(%s) AS b;',the_bit_string,to_keep );
	RAISE NOTICE 'the_query : "%"',_the_query;
	EXECUTE _the_query INTO _the_result;
	RETURN  _the_result.b;
	
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
	SELECT rc_MSB( CAST('1010010001' AS bit varying) ,3);


DROP FUNCTION IF EXISTS public.rc_LSB(the_bit_string anyelement, to_keep int);
CREATE OR REPLACE FUNCTION public.rc_LSB(the_bit_string anyelement, to_keep int)
RETURNS anyelement AS
$BODY$
DECLARE
_the_query text;
_the_result record;
BEGIN
	_the_query := format('
		WITH the_binary AS (
		SELECT  ''%s''::bit varying  AS b
		)
		SELECT (tb.b<<(bit_length(tb.b)-%s))::bit(%s) AS b
		FROM the_binary tb;'
		,the_bit_string,to_keep,to_keep );
		
	RAISE NOTICE 'the_query : "%"',_the_query;
	EXECUTE _the_query INTO _the_result;
	RETURN  _the_result.b;
	
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
	SELECT rc_LSB('1010010001' ::bit varying, 19);


--function computing distance (square norm) only to nearest fixed point at half_the_range.
DROP FUNCTION IF EXISTS public.rc_distancePPfixe(x int ,y int, xf int[], yf int[],the_range int);
CREATE OR REPLACE FUNCTION public.rc_distancePPfixe(x int ,y int, xf int[], yf int[] ,the_half_range int)
RETURNS int AS
$BODY$
DECLARE
BEGIN
	RETURN sum(rc_distancePPfixe(x_,y_,xf_,yf_,the_half_range_)) FROM
			(SELECT x x_,y y_, unnest(xf) AS xf_, unnest(yf) AS yf_, the_half_range AS the_half_range_) AS foo;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;


WITH the_data AS (
SELECT 1 AS x, 2 AS y, ARRAY[1,6,10,14] AS xf, ARRAY[1,6,10,14] AS yf, 2 the_range
)
SELECT public.rc_distancePPfixe(x,y,xf, yf,the_range)
FROM the_data


--missing a function to generate fix pointsdepending on power of 2

--function to generate fixe points given a number of depth in tree
DROP FUNCTION IF EXISTS public.rc_GenerateFixePoints(xmin int ,ymin int, xmax int, ymax int,the_power_of_2 int);
CREATE OR REPLACE FUNCTION public.rc_GenerateFixePoints(xmin int ,ymin int, xmax int, ymax int,pow int)
RETURNS int[][] AS
$BODY$
DECLARE 
interv int := 2^pow;

_temp int[][];
s_v int := interv/2;

BEGIN
	for i in 1..interv LOOP
		FOR j in 1..interv LOOP
			--_temp[i][1] := --ARRAY[s_v+i* interv, s_v+j* interv];
			
			_temp[i][1] := s_v+i* interv;
			_temp[i][2] := s_v+j* interv;
			
			RAISE NOTICE 'i: % , _temp : "%"',i,_temp[i];
		END LOOP;
	END LOOP;
	RETURN _temp;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;

SELECT public.rc_GenerateFixePoints(xmin:=0 ,ymin:=0, xmax:=16, ymax:=16,pow :=3)


	

-- Create required type
DROP   TYPE IF EXISTS T_Grid CASCADE;
CREATE TYPE T_Grid AS (
  gcol  int4,
  grow  int4,
  geom geometry
);
-- Drop function is exists
DROP FUNCTION IF EXISTS ST_RegularGrid(geometry, NUMERIC, NUMERIC, BOOLEAN);
-- Now create the function
CREATE OR REPLACE FUNCTION ST_RegularGrid(p_geometry   geometry,
                                          p_TileSizeX  NUMERIC,
                                          p_TileSizeY  NUMERIC,
                                          p_point      BOOLEAN DEFAULT TRUE)
  RETURNS SETOF T_Grid AS
$BODY$
DECLARE
   v_mbr   geometry;
   v_srid  int4;
   v_halfX NUMERIC := p_TileSizeX / 2.0;
   v_halfY NUMERIC := p_TileSizeY / 2.0;
   v_loCol int4;
   v_hiCol int4;
   v_loRow int4;
   v_hiRow int4;
   v_grid  T_Grid;
BEGIN
   IF ( p_geometry IS NULL ) THEN
      RETURN;
   END IF;
   v_srid  := ST_SRID(p_geometry);
   v_mbr   := ST_Envelope(p_geometry);
   v_loCol := trunc((ST_XMIN(v_mbr) / p_TileSizeX)::NUMERIC );
   v_hiCol := CEIL( (ST_XMAX(v_mbr) / p_TileSizeX)::NUMERIC ) - 1;
   v_loRow := trunc((ST_YMIN(v_mbr) / p_TileSizeY)::NUMERIC );
   v_hiRow := CEIL( (ST_YMAX(v_mbr) / p_TileSizeY)::NUMERIC ) - 1;
   FOR v_col IN v_loCol..v_hiCol Loop
     FOR v_row IN v_loRow..v_hiRow Loop
         v_grid.gcol := v_col;
         v_grid.grow := v_row;
         IF ( p_point ) THEN
           v_grid.geom := ST_SetSRID(
                             ST_MakePoint((v_col * p_TileSizeX) + v_halfX,
                                          (v_row * p_TileSizeY) + V_HalfY),
                             v_srid);
         ELSE
           v_grid.geom := ST_SetSRID(
                             ST_MakeEnvelope((v_col * p_TileSizeX),
                                             (v_row * p_TileSizeY),
                                             (v_col * p_TileSizeX) + p_TileSizeX,
                                             (v_row * p_TileSizeY) + p_TileSizeY),
                             v_srid);
         END IF;
         RETURN NEXT v_grid;
     END Loop;
   END Loop;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100
  ROWS 1000;
-- Assign ownership
ALTER FUNCTION ST_RegularGrid(geometry, NUMERIC, NUMERIC, BOOLEAN)
  OWNER TO postgres;



SELECT gcol, grow,ST_AsText(geom) AS geomWKT
  FROM ST_RegularGrid(ST_GeomFromText('LINESTRING(0 0, 100 100)',0),20,20);


  