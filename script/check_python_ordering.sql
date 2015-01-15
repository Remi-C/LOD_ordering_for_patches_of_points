SELECT count(*)
FROM public.test_order_out_of_db 

SELECT sum(pc_numpoints(patch))
FROM public.test_order_out_of_db 

SELECT sum(pc_numpoints(patch))
FROM tmob_20140616.riegl_pcpatch_space 

SET enable_seqscan to true
SELECT count(*)  --, sum(pc_numpoints(patch))  
FROM tmob_20140616.riegl_pcpatch_space 
WHERE points_per_level IS NOT NULL 

WITH count AS (
	SELECT count(*) AS c  --, sum(pc_numpoints(patch))  
	FROM tmob_20140616.riegl_pcpatch_space 
	WHERE points_per_level IS NOT NULL 
)
SELECT c / 6554548.0
FROM count

59544045
--2173447802

0:15:10.959152

CREATE INDEX ON tmob_20140616.riegl_pcpatch_space  (points_per_level) ; 
62522851, 13.59 min
SELECT 59544045*60.0/15.16
59544045

3h : 24%
12h  : 100%?

SELECT 2000000000.0/12 

60 millions , 20 min
3 millions/min

180 millions/h

13 h , 217344;7802
SELECT 2173.447802/13

with patch as (
SELECT *
FROM public.test_order_out_of_db 
LIMIT 100
)
SELECT pc_get(pt


COPY ( 
	WITH patch AS ( 
		SELECT *
		FROM public.test_order_out_of_db 
		ORDER BY gid asC
		LIMIT 10000
	)
	SELECT round(PC_Get((pt).point,'X'),3)  as x
		, round(PC_Get((pt).point,'Y'),3) as y 
		, round(PC_Get((pt).point,'Z'),3) as  z
		, round(PC_Get((pt).point,'reflectance'),3) as reflectance
		,(pt).ordinality 
		,gid
-- 		, CASE WHEN (pt).ordinality  = r.points_per_level[1] THEN 0 
-- 			WHEN (pt).ordinality > rc_ArraySum(r.points_per_level,1) AND (pt).ordinality <= rc_ArraySum(r.points_per_level,2) THEN 1 
-- 			WHEN (pt).ordinality > rc_ArraySum(r.points_per_level,2) AND (pt).ordinality <= rc_ArraySum(r.points_per_level,3) THEN 2 
-- 			WHEN (pt).ordinality > rc_ArraySum(r.points_per_level,3) AND (pt).ordinality <= rc_ArraySum(r.points_per_level,4) THEN 3
-- 			WHEN (pt).ordinality > rc_ArraySum(r.points_per_level,4) AND (pt).ordinality <= rc_ArraySum(r.points_per_level,5) THEN 4
-- 			ELSE -1 END    AS level
			--,r.points_per_level
	FROM patch, 
		rc_explodeN_numbered( patch,-1) as pt  
	--WHERE pc_numpoints(patch) >=100
	--AND patch_area > 0.9
	--AND gid  = 4440 
	--LIMIT 1    
)
TO '/tmp/octree_python_exterior.csv' WITH CSV HEADER; 



create table multipolygon
(
    mpid         bigint                      not null,
    multip       Geography(multipolygon, 4326)    not null
);


CREATE SCHEMA errror_distance_geography;
SET search_path to errror_distance_geography, public ; 

DROP TABLE IF EXISTS  multipolygon ;
create table multipolygon(
    mpid         SERIAL                      not null,
    multip       Geography(multipolygon)    not null
);
 
insert into multipolygon 
values (1, ST_GeographyFromText('multipolygon(((0.20 0.10, 0.21 0.10, 0.22 0.10, 0.23 0.10, 0.24 0.10, 0.25 0.10, 0.26 0.10, 0.27 0.10, 0.28 0.10, 0.29 0.10, 0.30 0.10, 0.30 0.20, 0.29 0.20, 0.28 0.20, 0.27 0.20, 0.26 0.20, 0.25 0.20, 0.24 0.20, 0.23 0.20, 0.22 0.20, 0.21 0.20, 0.20 0.20, 0.20 0.10)))'));
insert into multipolygon 
values (2, ST_GeographyFromText('multipolygon(((0.25 0.15, 0.26 0.15, 0.27 0.15, 0.28 0.15, 0.29 0.15, 0.30 0.15, 0.31 0.15, 0.32 0.15, 0.33 0.15, 0.34 0.15, 0.35 0.15, 0.35 0.25, 0.34 0.25, 0.33 0.25, 0.32 0.25, 0.31 0.25, 0.30 0.25, 0.29 0.25, 0.28 0.25, 0.27 0.25, 0.26 0.25, 0.25 0.25, 0.25 0.15)))'));

SELECT *
FROM multipolygon   ;  

WITH the_geom_to_intersect AS (
	SELECT ST_GeographyFromText('MULTIPOLYGON(((0.27 0.17, 0.28 0.17, 0.28 0.19, 0.27 0.19, 0.27 0.17)))') AS geom
) 
SELECT 
	( geom && multip AND _ST_Distance(geom, multip , 0.0, false) < 0.00001 ) AS intersects_for_geography
	, _ST_Distance(geom,multip, 0.0, false) AS distance_for_geography
	,_st_distanceuncached(geom, multip, FALSE) AS uncached_distance_for_geography
	,( geom && multip AND _st_distanceuncached(geom, multip, FALSE) < 0.00001 )  intersects_for_geography_uncached
	,ST_IsEmpty(ST_Intersection(geom,multip)::geometry) is_intersection_empty_trick
from the_geom_to_intersect, multipolygon m1 
 