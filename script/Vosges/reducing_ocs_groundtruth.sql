
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

DROP TABLE IF EXISTS ground_truth_area ;
CREATE TABLE ocs.ground_truth_area AS 
SELECT row_number() over() as gid, ST_ConcaveHull(ST_Union( sgeom ),0.9, false)
FROM ocs."Export_Foret67"  

ALTER  TABLE ocs."Export_Foret67"   ADD column sgeom  geometry(Polygon,931008);
UPDATE ocs."Export_Foret67" SET sgeom = ST_SimplifyPreserveTopology(geom, 20);

SELECT sum(COALESCE(st_Npoints(geom),0))
FROM  ocs."Export_Foret67" 
WHERE ST_IsEmpty(sgeom)= false
AND sgeom IS NOT NULL




