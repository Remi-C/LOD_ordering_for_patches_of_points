
set search_path to vosges_2011, ocs, public;
---the file giving the ground truth appears to not cover all the lidar data.
--Thus, we compute a kind of convex hull to deduce the place where we have ground truth or not

SELECT *
FROM vosges_2011.las_vosges_proxy 
LIMIT 1;

SELECT *
FROM ocs."Export_Foret67"  
LIMIT 1;

SELECT *
FROM ocs."Export_Foret67"  
WHERE st_isvalid(geom)=false
LIMIT 1;




DROP TABLE IF EXISTS unioned_sgeom ;
CREATE TABLE ocs.unioned_sgeom AS 
SELECT row_number() over() as gid,d.geom as geom
FROM 
	(
		SELECT ST_Union(ST_Buffer(sgeom,25)) as un
		FROM ocs."Export_Foret67"
		) AS sub
		, st_dump(un) as d

DROP TABLE IF EXISTS ground_truth_area ;
CREATE TABLE ocs.ground_truth_area AS 
SELECT row_number() over() as gid,  ST_Buffer(ST_Union( ST_Buffer(geom,500) ),-500)  as geom 
FROM unioned_sgeom  ;
UPDATE ground_truth_area SET geom = ST_ExteriorRing(ST_GeometryN(geom,1))
UPDATE ground_truth_area SET geom = ST_MakePolygon(geom)


DROP TABLE IF EXISTS ocs.ground_truth_area_manual ;
CREATE TABLE ocs.ground_truth_area_manual (
	gid serial PRIMARY KEY
	, geom geometry(polygon, 931008)
) ; 
CREATE INDEX ON ocs.ground_truth_area_manual USING GIST (geom)

ALTER  TABLE ocs."Export_Foret67"   ADD column sgeom  geometry(Polygon,931008);
UPDATE ocs."Export_Foret67" SET sgeom = ST_SimplifyPreserveTopology(geom, 20);

SELECT sum(COALESCE(st_Npoints(geom),0))
FROM  ocs."Export_Foret67" 
WHERE ST_IsEmpty(sgeom)= false
AND sgeom IS NOT NULL




