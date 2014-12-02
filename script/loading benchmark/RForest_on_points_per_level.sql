-----------------------------
--Rémi C
--11/2014
--Thales TTS / IGN Matis-Cogit
---------------------------------------

SET search_path to benchmark_cassette_2013, public;  


  
CREATE INDEX ON riegl_pcpatch_space USING btree( (points_per_level[1]) ); 
CREATE INDEX ON riegl_pcpatch_space USING btree( (points_per_level[2]) ); 
CREATE INDEX ON riegl_pcpatch_space USING btree( (points_per_level[3]) ); 
CREATE INDEX ON riegl_pcpatch_space USING btree( (points_per_level[4]) ); 
CREATE INDEX ON riegl_pcpatch_space USING btree( (points_per_level[5]) ); 
CREATE INDEX ON riegl_pcpatch_space USING btree( (points_per_level[6]) ); 
CREATE INDEX ON riegl_pcpatch_space USING btree( (points_per_level[7]) ); 

SELECT gid 
FROM riegl_pcpatch_space
WHERE points_per_level[2] >=4 ;



DROP TABLE IF EXISTS  benchmark_classification ;
CREATE TABLE benchmark_classification (
	 id int
	,en text
	, fr text
	,l_en text
);

COPY benchmark_classification
FROM '/media/sf_E_RemiCura/PROJETS/fusion_terra_mob/observations/objects/classes.csv'
WITH CSV  HEADER DELIMITER  ';'



SELECT *
FROM benchmark_classification
 
 -- 0 undef
 -- 1 other
 -- 2 ground
 -- 3 object
 -- 4 building
-- 5 vegetation


--creating function
DROP FUNCTION IF EXISTS rc_simplify_classes(id_i int ,  OUT id_o int) ; 
CREATE OR REPLACE FUNCTION rc_simplify_classes(id_i int  ,  OUT id_o int)
AS $$ 
-- @brief : this function convert classes to simplify : building stay building, all ground becomes ground, all the other is objects, vegetationbecomes vegetation
DECLARE 
	sid int := (id_i/pow(10,8))::int; 
BEGIN
	--keep only 3 first digits 
	 
	SELECT CASE WHEN id_i = 202060000 then 5 --vegetation
		WHEN id_i = 203000000  THEN 4 --building
		WHEN id_i = 0 THEN 0
		WHEN id_i = 100000000 THEN 1 --other
		WHEN sid = 2 THEN 2
		WHEN sid = 3 THEN 3
		END   INTO id_o  ; 

RETURN ; 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT ;

SELECT *, rc_simplify_classes(id) 
FROM benchmark_classification ;

--this function read a patch and return the dominant class for points, that is the class that has the more points in it, along with th epercentage of this class


SELECT *, pc_get(pt,'class') , pc_get(pt)
FROM riegl_pcpatch_space, pc_explode(patch) as pt
WHERE pc_numpoints(patch) > 100
LIMIT 1 

 

--creating function
DROP FUNCTION IF EXISTS rc_dominant_class(ipatch PCPATCH ,  OUT simplidifed_id int, OUT proba_occurency FLOAT) ; 
CREATE OR REPLACE FUNCTION rc_dominant_class(ipatch PCPATCH  ,  OUT simplidifed_id int, OUT proba_occurency float )
AS $$ 
-- @brief : this function convert classes to simplify : building stay building, all ground becomes ground, all the other is objects, vegetationbecomes vegetation
DECLARE  
BEGIN

	
	WITH patch AS (
		SELECT  pc_numpoints(ipatch) as numpoints 
	)
	 ,points AS (
		SELECT simplified_class, count(*)*1.0 as points_per_class
		FROM  pc_explode(ipatch) as pt, rc_simplify_classes(pc_get(pt,'class')::int ) AS simplified_class
		GROUP BY   simplified_class
	)
		SELECT  simplified_class, points_per_class/numpoints*1.0 AS proba_per_class INTO simplidifed_id, proba_occurency
		FROM patch, points 
		ORDER BY proba_per_class DESC
		LIMIT 1 ; 

	 
RETURN ; 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT ;

SELECT rc_dominant_class(patch) 
	FROM riegl_pcpatch_space 
	WHERE pc_numpoints(patch) > 100
	LIMIT 1 
	OFFSET 3 ;

--adding the ground truth column to patch table
ALTER TABLE benchmark_cassette_2013.riegl_pcpatch_space ADD COLUMN dominant_simplified_class INT; 
ALTER TABLE benchmark_cassette_2013.riegl_pcpatch_space ADD COLUMN proba_occurency FLOAT; 

--computing the ground truth

-- WITH results AS (
-- 	SELECT gid, f.*
-- 	FROM benchmark_cassette_2013.riegl_pcpatch_space, rc_dominant_class(patch) AS f 
-- 	WHERE gid BETWEEN 1 AND 2
-- )
-- UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET (dominant_simplified_class, proba_occurency)  = (r.simplidifed_id, r.proba_occurency)
-- FROM results as r
-- WHERE riegl_pcpatch_space.gid = r.gid  

	 SELECT gid
	 FROM riegl_pcpatch_space
	--WHERE dominant_simplified_class IS NOT NULL --11708
	 WHERE points_per_level IS NOT NULL --11706
--11708

--constructing the feature vector : 
	 SELECT  gid,  points_per_level[1] as f1, points_per_level[2] as f2 ,points_per_level[3] as f3, points_per_level[4] as f4,dominant_simplified_class, proba_occurency
	 FROM riegl_pcpatch_space
	--WHERE dominant_simplified_class IS NOT NULL --11708
	 WHERE points_per_level IS NOT NULL --11706
		--AND proba_occurency>0.5
	 ORDER BY gid ASC


COPY (
 SELECT  gid,  points_per_level[1] as f1, points_per_level[2] as f2 ,points_per_level[3] as f3, points_per_level[4] as f4,dominant_simplified_class, proba_occurency
	 FROM riegl_pcpatch_space
	--WHERE dominant_simplified_class IS NOT NULL --11708
	 WHERE points_per_level IS NOT NULL --11706
		--AND proba_occurency>0.5
	 ORDER BY gid ASC
	
) TO '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/script/descriptor_vector.csv'
WITH CSV HEADER; 


 
	--a plpython function that use random forest to try to predict gt_class , usign cross validation.
DROP FUNCTION IF EXISTS rc_random_forest_cross_valid( gid FLOAT[], f1 FLOAT[], f2 FLOAT[], f3 FLOAT[], f4 FLOAT[], gt_class int[], proba float[]);
CREATE FUNCTION rc_random_forest_cross_valid ( gid FLOAT[], f1 FLOAT[], f2 FLOAT[], f3 FLOAT[], f4 FLOAT[], gt_class int[], proba float[]) 
RETURNS float--TABLE (gid int, predicted_class int, confidence float)
AS $$
"""
This function use random forest on an input vector to learn with half of the vector and  predit on the other half.
It returns the prediction

"""
#importing neede modules
import numpy as np ;   
from sklearn.ensemble import RandomForestClassifier ; 
from sklearn import cross_validation ; 
from sklearn import metrics ; 

#agglomering each array to get a nice numpy array of features
X = np.column_stack((np.array(f1),np.array(f2),np.array(f3),np.array(f4))); 
Y =  np.array(gt_class ) ; 

#plpy.notice(X);
#plpy.notice(Y);
clf = RandomForestClassifier(1, criterion="entropy" ,min_samples_leaf=20) ; 
#clf = clf.fit(X,Y ) ; 

kf_total = cross_validation.KFold(len(X), n_folds = 10, indices = True, shuffle = True, random_state = 4) ;
scores = cross_validation.cross_val_score(clf, X, Y, cv=kf_total, n_jobs = 1) ;

plpy.notice(scores.mean());
plpy.notice(scores.std()/2);
return np.mean(scores) ; 
 
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 

 -- 0 undef - very few 
 -- 1 other --not present
 -- 2 ground --1775
 -- 3 object --1106
 -- 4 building --8790
-- 5 vegetation -- 0

WIth prep_data AS (
	 SELECT  array_agg(gid ORDER BY gid ASC) AS gid
		,   array_agg(     COALESCE(points_per_level[1]/1.0,0)   ORDER BY gid ASC) as f1
		, array_agg(   COALESCE(points_per_level[2]/8.0,0)    ORDER BY gid ASC) as f2 
		, array_agg(  COALESCE(points_per_level[3]/64.0,0)    ORDER BY gid ASC) as f3
		,  array_agg(  COALESCE(points_per_level[4]/512.0,0)    ORDER BY gid ASC) as f4
		, array_agg( dominant_simplified_class
			--CASE WHEN dominant_simplified_class !=2 THEN 0 ELSE dominant_simplified_class END 
			
			ORDER BY gid ASC) as gt_class
		,  array_agg(proba_occurency ORDER BY gid ASC) AS proba 
	 FROM riegl_pcpatch_space
	--WHERE dominant_simplified_class IS NOT NULL --11708
	 WHERE points_per_level IS NOT NULL --11706 
		--AND proba_occurency>0.5
		--AND  NOT (dominant_simplified_class = ANY (ARRAY[0,1,3]))
		--AND  proba_occurency>0.95
		AND (dominant_simplified_class = 2 AND proba_occurency< 0.90)=FALSE
)
 SELECT  rc_random_forest_cross_valid(gid,f1,f2,f3,f4,gt_class,proba)
	 FROM prep_data ;




	--a plpython predicting gt_class, cross_validation , result per class 
DROP FUNCTION IF EXISTS rc_random_forest_cross_valid_per_class( gid FLOAT[], f1 FLOAT[], f2 FLOAT[], f3 FLOAT[], f4 FLOAT[], gt_class int[], proba float[],int ,int);
CREATE FUNCTION rc_random_forest_cross_valid_per_class ( gid FLOAT[], f1 FLOAT[], f2 FLOAT[], f3 FLOAT[], f4 FLOAT[], gt_class int[], proba float[],kfold int default 5, tree_number int default 10 ) 
RETURNS TABLE(gt_class float, correct_prediction float )--TABLE (gid int, predicted_class int, confidence float)
AS $$
"""
This function use random forest on an input vector to learn with half of the vector and  predit on the other half.
It returns the prediction

"""
#importing neede modules 
import matplotlib ;
matplotlib.use('Agg') ;
import numpy as np ;   
from sklearn.ensemble import RandomForestClassifier ; 
from sklearn import cross_validation,preprocessing ;  
import pandas as pd; 
import matplotlib.pyplot as plt
from sklearn.tree import DecisionTreeClassifier;


##########
#parameters
k_folds = kfold ; # for cross validation. Learn on 9/K_folds, test on 1/KFolds
random_forest_trees = tree_number ; # how much trees in the forest
##########

#agglomering each array to get a nice numpy array of features
X = np.column_stack((np.array(f1),np.array(f2),np.array(f3),np.array(f4))); 
Y =  np.array(gt_class ) ; 
 #to try random forest
clf = RandomForestClassifier(random_forest_trees, criterion="entropy" ,min_samples_leaf=20) ; 

#to try decision tree
#clf = DecisionTreeClassifier(criterion='entropy', splitter='best', max_depth=None, min_samples_split=10, min_samples_leaf=1,   max_features=None, random_state=4 ) ; 
#clf = clf.fit(X,Y ) ; 
scaler = preprocessing.StandardScaler().fit(X) ;  


kf_total = cross_validation.KFold(len(X), n_folds = k_folds, indices = True, shuffle = True, random_state = 4) ;

for i ,(train, test)  in enumerate(kf_total) :  
	#print train , test
	X_train, X_test, Y_train, Y_test = X[train],X[test], Y[train], Y[test] ; 
	tmp = clf.fit(scaler.transform(X_train),Y_train) ; 
	tmp_prob = clf.predict_proba(scaler.transform(X_test)) ;
	#tmp_prob ;
	#finding the result per class
	max_ix = np.argmax(tmp_prob,axis=1) ; 
	indice_of_chosen_class =  np.unravel_index(max_ix, tmp_prob.shape)[1].T 
	chosen_class = clf.classes_[indice_of_chosen_class]
	#chosen_class == Y_test ;

	#getting the highest value 
	max_values = np.amax(tmp_prob,axis=1);

	#grouping for score per class
	proba_class_chosen = np.column_stack( (max_values,chosen_class, chosen_class == Y_test) ) ; 
	df = pd.DataFrame(proba_class_chosen, columns = ("proba_chosen","class_chosen","is_correct")) ; 
	print i ; 
	if i == 0 :
		result = df;
	else:
		result = result.append( df,ignore_index=True) ; 
	plpy.notice("feature used, by importcy");
	plpy.notice(clf.feature_importances_)
    
grouped_result = result.groupby(["class_chosen"])   
mean_result  = grouped_result.aggregate(np.mean) ;   
grouped_proba = grouped_result['proba_chosen',"is_correct"]
for name, group in grouped_proba :
	#print(name)
	#print(group.sort(columns="proba_chosen" ).cumsum() )
	g2 = group.sort(columns="proba_chosen",ascending=False )
	g2['is_wrong'] =g2.is_correct==False ; 
	g2['new_index'] =  np.arange(1, len(g2)+1 ) *1.0 /len(g2); 

	g2['cum_sum'] =g2.is_correct.cumsum() 
	g2['result_prediction'] =100*g2.cum_sum/( g2.new_index*len(g2) )
	g2['x_axis'] =1- g2['proba_chosen']  ;
	plot = g2.plot(x='x_axis', y= 'result_prediction',ylim=[-10,110], title="using prediction by descending confidence for class "+str(int(name))  )
	labx = plt.xlabel("1-minimal_confidence")
	laby = plt.ylabel("precision_of_prediction")
	plt.axhline(y=g2['result_prediction'].mean(), label='mean_line')
	#plt.plot(x=g2['x_axis'],y=100*g2['new_index']/len(g2))
	#title = title("using prediction by descending confidence")
	#ylim = ylim([-10,110]) 
	save  = plt.savefig(
		'/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/result_rforest/test_output_'
		#+ str(int( np.amax(clf.classes_)))
		#+'_against_all_'
		+str(int(name)) 
		+'_.jpg')
	plt.close() 

to_be_returned = np.column_stack(((np.trunc(mean_result.to_records(index=True)["class_chosen"])).astype(int),mean_result.to_records(index=True)["is_correct"] ))
plpy.notice(type(to_be_returned));
return to_be_returned.tolist();
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 

	 
	WIth prep_data AS (
		 SELECT  array_agg(gid ORDER BY gid ASC) AS gid
			,   array_agg(     COALESCE(points_per_level[1]/1.0,0)   ORDER BY gid ASC) as f1
			, array_agg(   COALESCE(points_per_level[2]/8.0,0)    ORDER BY gid ASC) as f2 
			, array_agg(  COALESCE(points_per_level[3]/64.0,0)    ORDER BY gid ASC) as f3
			,  array_agg(  COALESCE(points_per_level[4]/512.0,0)    ORDER BY gid ASC) as f4
			, array_agg( dominant_simplified_class 
				--CASE WHEN dominant_simplified_class !=4 THEN 0 ELSE dominant_simplified_class END
				ORDER BY gid ASC) as gt_class
			,  array_agg(proba_occurency ORDER BY gid ASC) AS proba 
			--SELECT dominant_simplified_class, count(*)  
		 FROM riegl_pcpatch_space 
		 WHERE points_per_level IS NOT NULL --11706  
			AND NOT (dominant_simplified_class = ANY (ARRAY[0,1]))
		-- AND (dominant_simplified_class = 2 AND proba_occurency< 0.95)=FALSE --avoiding mixed ground patch
		AND ( dominant_simplified_class=4 AND random()>0.25)=FALSE
			--GROUP BY dominant_simplified_class
			--ORDER BY dominant_simplified_class
			--AND gid < 1000
	)
	SELECT  r.* 
	FROM prep_data,rc_random_forest_cross_valid_per_class(gid,f1,f2,f3,f4,gt_class,proba) as r ;




--creating the vegetation benchmark :
--exporting points near luexmbour garden, along with gid

SELECT st_srid(geom)
FROM public.def_zone_test  

SELECT count(*)
FROM public.def_zone_test  as dzt , acquisition_tmob_012013.riegl_pcpatch_space  as rps
WHERE ST_Intersects(dzt.geom,rps.patch::geometry) = true
	AND pc_numpoints(patch)>=30
	AND pc_numpoints(patch) <=1000

COPY 
(
SELECT 
	 round(pc_get(pt,'x')::numeric,3) AS x
	, round(pc_get(pt,'y')::numeric,3) as y
	, round(pc_get(pt,'z')::numeric,3) as z 
	, round(pc_get(pt,'reflectance')::numeric,3) as reflectance
	, rps.gid 
FROM public.def_zone_test  as dzt , acquisition_tmob_012013.riegl_pcpatch_space  as rps , pc_explode(patch) AS pt
WHERE ST_Intersects(dzt.geom,rps.patch::geometry) = true
	AND pc_numpoints(patch)>=30
	AND pc_numpoints(patch) <=1000
	AND points_per_level is not null
)
TO '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/adding_vegetation/database_output.csv'
WITH CSV HEADER ; 


--removing all that is not vegetation from point cloud

--import the vegetation only point cloud

DROP TABLE IF EXISTS vegetation_pointcloud ;
CREATE TABLE vegetation_pointcloud (
x float,
y float,
z float,
gid float,
reflectance float
) ;

COPY vegetation_pointcloud FROM '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/adding_vegetation/only_vegetation.csv' WITH CSV HEADER DELIMITER AS E'\t'

ALTER TABLE vegetation_pointcloud ALTER COLUMN gid TYPE int using (round(gid)::int);

CREATE INDEX ON vegetation_pointcloud (gid); 

--find list of unique gid in pointcloud
--for each gid, set the dominant_simplified_class to 5 (vegetation)
	--adding dominant_simplified_class to the table

	ALTER TABLE acquisition_tmob_012013.riegl_pcpatch_space  ADD COLUMN dominant_simplified_class INT; 
	ALTER TABLE acquisition_tmob_012013.riegl_pcpatch_space  ADD COLUMN proba_occurency float; 

	CREATE INDEX ON acquisition_tmob_012013.riegl_pcpatch_space (dominant_simplified_class) ; 

	WITH gid_to_fill AS (
		SELECT distinct gid
		FROM vegetation_pointcloud
	)
	update acquisition_tmob_012013.riegl_pcpatch_space SET  (dominant_simplified_class, proba_occurency) 
	= (5,1.0)
	FROM  gid_to_fill
	WHERE gid_to_fill.gid = riegl_pcpatch_space.gid ; 


--now, new query using both data set

	WITH patch_to_use AS (
			 SELECT gid ,'bench' AS src  ,points_per_level 
				, 	dominant_simplified_class  
					--CASE WHEN  dominant_simplified_class !=2 THEN 0 ELSE  dominant_simplified_class END
				,proba_occurency 
				,random() as rand
			 FROM benchmark_cassette_2013.riegl_pcpatch_space 
			WHERE points_per_level IS NOT NULL
				AND dominant_simplified_class IS NOT NULL
			 UNION ALL
			 SELECT gid  ,'tmob' AS src ,points_per_level 
				, 	dominant_simplified_class  
					--CASE WHEN  dominant_simplified_class !=2 THEN 0 ELSE  dominant_simplified_class END
				,proba_occurency 
				,random() as rand
			 FROM acquisition_tmob_012013.riegl_pcpatch_space 
			 WHERE points_per_level IS NOT NULL  
				AND dominant_simplified_class IS NOT NULL
	)
	,count_per_class as (
		SELECT dominant_simplified_class , count(*) AS  obs_per_class
		FROM  patch_to_use 
		GROUP BY dominant_simplified_class
			
	) 
	,array_agg AS (
		SELECT 
			array_agg(gid ORDER BY gid ASC) AS gid
			,   array_agg(     COALESCE(points_per_level[2]/8.0,0)   ORDER BY gid ASC) as f1
			, array_agg(   COALESCE(points_per_level[3]/64.0,0)    ORDER BY gid ASC) as f2 
			, array_agg(  COALESCE(points_per_level[4]/512.0,0)    ORDER BY gid ASC) as f3
			,  array_agg(  COALESCE(points_per_level[5]/4096.0,0)    ORDER BY gid ASC) as f4
			, array_agg(  
				ptu.dominant_simplified_class 
				--CASE WHEN ptu.dominant_simplified_class !=5 THEN 0 ELSE ptu.dominant_simplified_class END
				ORDER BY gid ASC) as gt_class
			,  array_agg(proba_occurency ORDER BY gid ASC) AS proba 
		FROM patch_to_use AS ptu LEFT OUTER JOIN count_per_class AS cpc ON (cpc.dominant_simplified_class = ptu.dominant_simplified_class)
			WHERE 
				--(dominant_simplified_class=5 AND random() <0.90) = false
				--AND (dominant_simplified_class=4 AND random() <0.83) = false
				 NOT (ptu.dominant_simplified_class = ANY (ARRAY[0, 1]))
				AND rand  < 1000.0/(  obs_per_class::float) --this allows to have approx 1000 obs per class 
	) 
	SELECT  r.* 
	FROM array_agg,rc_random_forest_cross_valid_per_class(gid,f1,f2,f3,f4,gt_class,proba,10,30) as r ; 
		