SET search_path to vosges_2011, public ; 



UPDATE las_vosges_proxy SET (avg_height, avg_Z,avg_intensity, avg_tot_return_number) = 
	(patch_height,z_avg,intensity_avg,tot_return_number_avg )
	FROM (
		SELECT gid,COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0) AS patch_height  
		,COALESCE( round(PC_PatchAvg(patch, 'Z'),3),0 ) AS z_avg
		,  COALESCE( round(PC_PatchAvg(patch, 'intensity'),3),0 ) AS intensity_avg
		,  COALESCE( round(PC_PatchAvg(patch, 'tot_return_number') ,3),0) AS tot_return_number_avg
	FROM las_vosges 
	WHERE gid = 10000
	) AS sub
	WHERE  sub.gid = las_vosges_proxy.gid


DECLARE @I,@S ;
SET @I=0;
SET @S = 100; 
WHILE @I <600000
BEGIN   
UPDATE las_vosges_proxy SET (file_name,geom,num_points,avg_height, avg_Z,avg_intensity, avg_tot_return_number) = 
	(sub.file_name,sub.geom,sub.num_points, patch_height,z_avg,intensity_avg,tot_return_number_avg )
	FROM (
		SELECT gid
			,patch::geometry as geom
			, file_name
			, pc_numpoints(patch) as num_points
			, COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0) AS patch_height  
			,COALESCE( round(PC_PatchAvg(patch, 'Z'),3),0 ) AS z_avg
			,  COALESCE( round(PC_PatchAvg(patch, 'intensity'),3),0 ) AS intensity_avg
			,  COALESCE( round(PC_PatchAvg(patch, 'tot_return_number') ,3),0) AS tot_return_number_avg
	FROM las_vosges 
	WHERE gid BETWEEN @I AND @I+@S
	) AS sub
	WHERE  sub.gid = las_vosges_proxy.gid ;
	SET @I = @I + @S ; 
END


SELECT *
FROM las_vosges_proxy 
WHERE avg_intensity IS NOT NULL

 

UPDATE las_vosges_proxy SET (file_name,geom,num_points,avg_height, avg_Z,avg_intensity, avg_tot_return_number) = 
		(sub.file_name,sub.geom,sub.num_points, patch_height,z_avg,intensity_avg,tot_return_number_avg )
	FROM (
		SELECT gid
			,patch::geometry as geom
			, file_name
			, pc_numpoints(patch) as num_points
			, COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0) AS patch_height  
			,COALESCE( round(PC_PatchAvg(patch, 'Z'),3),0 ) AS z_avg
			,  COALESCE( round(PC_PatchAvg(patch, 'intensity'),3),0 ) AS intensity_avg
			,  COALESCE( round(PC_PatchAvg(patch, 'tot_return_number') ,3),0) AS tot_return_number_avg
	FROM las_vosges 
	WHERE gid BETWEEN  10000 AND 10010
	) as sub
	WHERE  sub.gid = las_vosges_proxy.gid ;



 --for each patch, look in which polygon describing ground occupation it is.
UPDATE las_vosges_proxy SET (gt_src, gt_classes, gt_weight) =(src,cla, wei)
FROM (  
WITH map AS ( 
	SELECT p.gid AS patch_id
		, ocs.gid AS ocs_gid
		, ocs.tfv
		, round(CAST(ST_Area(ST_Intersection(ocs.geom,p.patch::geometry))
			/ ( CASE WHEN  ST_Area(p.patch::geometry) !=0 THEN ST_Area(p.patch::geometry) ELSE  1 END ) AS NUMERIC),2) as shared_surf
	from vosges_2011.las_vosges as p
		INNER JOIN  ocs."Export_Foret67" as ocs ON (ST_Intersects(ocs.geom,p.patch::geometry)=TRUE )   
)
	SELECT patch_id as gid
		,array_agg(ocs_gid ORDER BY shared_surf DESC, tfv asc,ocs_gid asc ) AS src 
		, array_agg(tfv ORDER BY shared_surf DESC, tfv asc,ocs_gid asc) AS cla 
		, array_agg(shared_surf ORDER BY shared_surf DESC, tfv ASC, ocs_gid asc) AS wei  
	FROM map
	WHERE shared_surf > 0.01

	GROUP BY gid 
) AS sub
WHERE las_vosges_proxy.gid = sub.gid 

UPDATE las_vosges_proxy SET (gt_classes,gt_weight ) = (ARRAY['NoClass'], ARRAY[1]) WHERE gt_src IS NULL
SELECT *
FROM las_vosges_proxy
LIMIT 100


 

SELECT count(*)
FROM las_vosges_proxy
WHERE points_per_level IS  NULL ;

DECLARE @I,@S ;
SET @I=0;
SET @S = 1000; 
WHILE @I <600000
BEGIN   
UPDATE las_vosges_proxy SET (points_per_level) = 
		(ppl)
	FROM (
		SELECT gid
			,points_per_level as ppl
	FROM las_vosges 
	WHERE points_per_level IS NOT NULL
		AND  las_vosges.gid BETWEEN @I AND @I+@S
	) as sub 
	WHERE  sub.gid = las_vosges_proxy.gid ;
	SET @I = @I + @S ; 
END
