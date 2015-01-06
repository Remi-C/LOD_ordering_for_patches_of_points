

SET search_path to benchmark_cassette_2013, vosges_2011, public;


ALTER TABLE benchmark_cassette_2013.riegl_pcpatch_proxy ADD COLUMN num_points INT
CREATE INDEX ON riegl_pcpatch_proxy (num_points);

UPDATE riegl_pcpatch_proxy AS rpp SET num_points = PC_NUmPoints(patch)
FROM acquisition_tmob_012013.riegl_pcpatch_space  AS rps
WHERE rps.gid = rpp.gid ;


SELECT *
FROM vosges_2011.las_vosges_proxy  
LIMIT 100 




WITH npoints_vosges AS (
	SELECT  array_agg(log(num_points)) as np1
	FROM vosges_2011.las_vosges_proxy  
 )
 , npoints_bench AS (
	SELECT array_agg(log(num_points)) as np2
	FROM  benchmark_cassette_2013.riegl_pcpatch_proxy
 )
 SELECT r.*
 FROM npoints_vosges,   npoints_bench
	,rc_py_plot_2_hist(
		np1,np2
		,'/media/sf_USB_storage_local/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/for_article/histogram_of_density/paris_vosges_density_hist_2.svg'
		,ARRAY['Density of Vosges data set','Density of Paris data set' ]
		,50
		,use_log_y := true) as r 

	