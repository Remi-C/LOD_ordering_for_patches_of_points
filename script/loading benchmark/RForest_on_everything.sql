-----------------------------
--Rémi C
--11/2014
--Thales TTS / IGN Matis-Cogit
---------------------------------------
--We try to do best that we can we all ready made simple descriptors
--
SET search_path to benchmark_cassette_2013, public;

--adding descriptor
	-- height of the patch
	-- height above the laser
	-- area of the patch (2D)
	-- range of reflectance 
	--max(numbe rof echo ) 

SELECT *
FROM acquisition_tmob_012013.riegl_pcpatch_space 
LIMIT 1 

ALTER TABLE riegl_pcpatch_space  ADD COLUMN patch_height float; 
ALTER TABLE riegl_pcpatch_space  ADD COLUMN height_above_laser float; 
ALTER TABLE riegl_pcpatch_space  ADD COLUMN patch_area float; 
ALTER TABLE riegl_pcpatch_space  ADD COLUMN reflectance_avg float; 
ALTER TABLE riegl_pcpatch_space  ADD COLUMN nb_of_echo_avg float; 

CREATE INDEX ON riegl_pcpatch_space (patch_height) ;
CREATE INDEX ON riegl_pcpatch_space (height_above_laser) ;  
CREATE INDEX ON riegl_pcpatch_space (patch_area) ;  
CREATE INDEX ON riegl_pcpatch_space (reflectance_avg) ;  
CREATE INDEX ON riegl_pcpatch_space (nb_of_echo_avg) ;  

--filling  :

SELECT COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0) AS patch_height
	,  COALESCE( round(PC_PatchAvg(patch, 'z_origin'),3),0 ) AS height_above_laser
	, COALESCE(round(ST_Area(patch::geometry)::numeric,3),0) AS patch_area
	,  COALESCE( round(PC_PatchAvg(patch, 'reflectance'),3),0 ) AS reflectance_avg
	,  COALESCE( round(PC_PatchAvg(patch, 'nb_of_echo') ,3),0) AS nb_of_echo_avg
FROM riegl_pcpatch_space 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL
LIMIT 1  ; 


UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET  (patch_height,height_above_laser,patch_area,reflectance_avg,nb_of_echo_avg) = 
	(COALESCE( round(PC_PatchMax(patch, 'Z')-PC_PatchMin(patch, 'Z'),3),0)  
	,  COALESCE( round(PC_PatchMin(patch, 'Z')-PC_PatchAvg(patch, 'z_origin') ,3),0 )  
	, COALESCE(round(rc_pcpatch_real_area_N(patch,85,0.06,0.2)::numeric,3),0)  
	,  COALESCE( round(PC_PatchAvg(patch, 'reflectance'),3),0 ) 
	,  COALESCE( round(PC_PatchAvg(patch, 'nb_of_echo') ,3),0)   ) 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
AND gid =1125;

UPDATE benchmark_cassette_2013.riegl_pcpatch_space SET  (patch_height ,height_above_laser, reflectance_avg,nb_of_echo_avg) = 
	(ROW(rc_pcpatch_compute_crude_descriptors(patch ))   )
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
AND gid =1125;


rc_pcpatch_compute_crude_descriptors(patch ) 

SELECT patch_height,height_above_laser,patch_area,reflectance_avg,nb_of_echo_avg
FROM riegl_pcpatch_space 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
 AND gid <6000
LIMIT  100;


SELECT *
FROM acquisition_tmob_012013.riegl_pcpatch_space  


SELECT rc_pcpatch_real_area_N(patch,85,0.06,0.2)
FROM riegl_pcpatch_space 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
AND gid = 1125;



DROP FUNCTION IF EXISTS rc_pcpatch_real_area_N( ipatch PCPATCH, n_points int, point_size float, reg_size float, OUT approx_area float) ; 
CREATE OR REPLACE FUNCTION rc_pcpatch_real_area_N(ipatch PCPATCH, n_points int DEFAULT 85, point_size float DEFAULT 0.06, reg_size float DEFAULT 0.2, OUT approx_area float)
AS $$ 
-- @brief : this function takes only first points of a patch, then use it to compute an approx area
DECLARE  
BEGIN
	--keep only 3 first digits 
	SELECT ST_Area( 
			ST_Buffer(
				ST_Union(
					ST_Buffer(  (pt).point::geometry   ,reg_size,'quad_segs=2')
				)
			,-(reg_size-point_size)
			) ) into approx_area  
FROM  rc_explodeN_numbered(ipatch,n_points) as pt  ;

RETURN ; 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT ;

DROP FUNCTION IF EXISTS rc_pcpatch_compute_crude_descriptors( ipatch PCPATCH ) ; 
CREATE OR REPLACE FUNCTION rc_pcpatch_compute_crude_descriptors(ipatch PCPATCH ,out  patch_height float, out height_above_laser float, out reflectance_avg float, out nb_of_echo_avg float  )
AS $$ 
-- @brief : this function takes only first points of a patch, then use it to compute an approx area
DECLARE  
BEGIN
	SELECT  COALESCE( round(max(z)-min(z),3),0 )
		,  COALESCE( round(min(z)-avg(z_origin ),3),0 ) 
		,   COALESCE( round(avg(reflectance),3),0 ) 
		,  COALESCE( round(avg(nb_of_echo),3),0 )  into patch_height,height_above_laser,reflectance_avg,nb_of_echo_avg
	FROM 
		 (SELECT 
			(pt).ordinality 
			, COALESCE( round(pc_get((pt).point,'z'),3),0 ) as z
			, COALESCE( round(pc_get((pt).point,'z_origin'),3),0 ) as z_origin 
			, COALESCE( round(pc_get((pt).point,'reflectance'),3),0 ) as  reflectance
			, COALESCE( round(pc_get((pt).point,'nb_of_echo'),3),0 )  as nb_of_echo
		FROM   rc_explodeN_numbered(ipatch,1000) as pt ) AS points ;

RETURN ; 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT ;




	

WITH points AS (
	SELECT 
		(pt).ordinality 
		, COALESCE( round(pc_get((pt).point,'z'),3),0 ) as z
		, COALESCE( round(pc_get((pt).point,'z_origin'),3),0 ) as z_origin 
		, COALESCE( round(pc_get((pt).point,'reflectance'),3),0 ) as  reflectance
		, COALESCE( round(pc_get((pt).point,'nb_of_echo'),3),0 )  as nb_of_echo
	FROM riegl_pcpatch_space , rc_explodeN_numbered(patch,1000) as pt 
	WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL 
	AND gid = 1125 
)



SELECT  COALESCE( round(max(z)-min(z),3),0 ) AS patch_height
	,  COALESCE( round(min(z)-avg(z_origin ),3),0 ) AS height_above_laser 
	,   COALESCE( round(avg(reflectance),3),0 ) AS reflectance_avg
	,  COALESCE( round(avg(nb_of_echo),3),0 ) AS nb_of_echo_avg
FROM points 
WHERE dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL
LIMIT 1  ; 


SELECT count(*)
FROM riegl_pcpatch_space   
where ( dominant_simplified_class IS NOT NULL AND points_per_level IS NOT NULL) 





	--a plpython predicting gt_class, cross_validation , result per class 
DROP FUNCTION IF EXISTS rc_random_forest_cross_valid_per_class_all_features( gid FLOAT[], f1 FLOAT[], f2 FLOAT[], f3 FLOAT[], f4 FLOAT[], f5 FLOAT[], f6 FLOAT[], f7 FLOAT[], f8 FLOAT[],f9 float[], gt_class int[], proba float[],int ,int);
CREATE FUNCTION rc_random_forest_cross_valid_per_class_all_features ( gid FLOAT[], f1 FLOAT[], f2 FLOAT[], f3 FLOAT[], f4 FLOAT[], f5 FLOAT[], f6 FLOAT[], f7 FLOAT[], f8 FLOAT[],f9 float[], gt_class int[], proba float[],kfold int default 5, tree_number int default 10) 
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
from sklearn.metrics import confusion_matrix


##########
#parameters
k_folds = kfold ; # for cross validation. Learn on 9/K_folds, test on 1/KFolds
random_forest_trees = tree_number ; # how much trees in the forest
labels=  np.zeros(6, dtype={'names':['class_id', 'class_name'], 'formats':['i4','a10']})  
labels[:] =  [(0,"undef" ),(1,"other"),(2,"ground"),(3,"object"),(4,"building"),(5,"vegetation")]  
##########

#agglomering each array to get a nice numpy array of features
X = np.column_stack((np.array(f1),np.array(f2),np.array(f3),np.array(f4),np.array(f5),np.array(f6),np.array(f7),np.array(f8),np.array(f9)    )); 
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
	proba_class_chosen = np.column_stack( (max_values,chosen_class, chosen_class == Y_test,Y_test ) ) ; 
	df = pd.DataFrame(proba_class_chosen, columns = ("proba_chosen","class_chosen","is_correct","ground_truth_class" )) ; 
	print i ; 
	if i == 0 :
		result = df;
	else:
		result = result.append( df,ignore_index=True) ; 
	plpy.notice("feature used, by importcy");
	plpy.notice(clf.feature_importances_)
    
grouped_result = result.groupby(["class_chosen"])   
mean_result  = grouped_result.aggregate(np.mean) ;   
grouped_proba = grouped_result['proba_chosen',"is_correct","ground_truth_class"]
for name, group in grouped_proba :
	#print(name)
	#print(group.sort(columns="proba_chosen" ).cumsum() )
	g2 = group.sort(columns="proba_chosen",ascending=False )
	g2['is_wrong'] =g2.is_correct==False ; 
	g2['new_index'] =  np.arange(1, len(g2)+1 ) *1.0 /len(g2); 

	g2['cum_sum'] =g2.is_correct.cumsum() 
	g2['result_prediction'] =100*g2.cum_sum/( g2.new_index*len(g2) )
	g2['x_axis'] =1- g2['proba_chosen']  ;


	plt.clf()
	plt.cla()
	plt.close() 
	
	plot = g2.plot(x='x_axis', y= 'result_prediction',ylim=[-10,110], title="using prediction by descending confidence for class "+str(int(name))  )
	labx = plt.xlabel("1-minimal_confidence")
	laby = plt.ylabel("precision_of_prediction")
	plt.axhline(y=g2['result_prediction'].mean(), label='mean_line')
	#plt.plot(x=g2['x_axis'],y=100*g2['new_index']/len(g2))
	#title = title("using prediction by descending confidence")
	#ylim = ylim([-10,110]) 
	save  = plt.savefig(
		'/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/result_rforest/test_output_all_feature_'
		#+ str(int( np.amax(clf.classes_)))
		#+'_against_all_'
		+str(int(name)) 
		+'_.jpg') ; 
	
	plt.clf()
	plt.cla()
	plt.close() 


plt.clf()
plt.close() ;
plt.cla ;
cm = confusion_matrix(result['ground_truth_class'], result['class_chosen']) 
cm = cm * 1.0 ;
preprocessing.normalize(cm, norm='l1', axis=0,copy=False)
plpy.notice(cm); 
fig = plt.figure()
ax = fig.add_subplot(111)
cax = ax.matshow(cm,cmap = plt.get_cmap('YlOrBr'),vmin=0, vmax=1) 
plt.title('Confusion matrix of the classifier')
fig.colorbar(cax, cmap = plt.get_cmap('YlOrBr') )
ax.set_xticklabels([''] + list(labels[clf.classes_]['class_name']) )
ax.set_yticklabels([''] + list(labels[clf.classes_]['class_name']) )
plt.xlabel('Predicted')
plt.ylabel('True') 
for i, cas in enumerate(cm):
	for j, c in enumerate(cas):
		if c>0:
			plt.text(j-.2, i+.2, str(round(c, 3)), fontsize=12)
plt.savefig('/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/result_rforest/test_output_all_feature_confusion_matrix_.png')
plt.clf()
plt.cla()
plt.close() 

to_be_returned = np.column_stack(((np.trunc(mean_result.to_records(index=True)["class_chosen"])).astype(int),mean_result.to_records(index=True)["is_correct"] ))
plpy.notice(type(to_be_returned));
return to_be_returned.tolist();
$$ LANGUAGE plpythonu IMMUTABLE STRICT; 



WITH patch_to_use AS (
			 SELECT gid ,'bench' AS src  ,points_per_level 
				, 	dominant_simplified_class  
					--CASE WHEN  dominant_simplified_class !=2 THEN 0 ELSE  dominant_simplified_class END
				, patch_height,height_above_laser,patch_area,reflectance_avg,nb_of_echo_avg
				,proba_occurency 
				,random() as rand
			 FROM benchmark_cassette_2013.riegl_pcpatch_space 
			WHERE points_per_level IS NOT NULL
				AND dominant_simplified_class IS NOT NULL
			 UNION ALL
			 SELECT gid  ,'tmob' AS src ,points_per_level 
				, 	dominant_simplified_class  
					--CASE WHEN  dominant_simplified_class !=2 THEN 0 ELSE  dominant_simplified_class END
				,patch_height,height_above_laser,patch_area,reflectance_avg,nb_of_echo_avg
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
			,  array_agg(     COALESCE(patch_height)   ORDER BY gid ASC) as f5
			, array_agg(   COALESCE(height_above_laser)    ORDER BY gid ASC) as f6
			, array_agg(  COALESCE(patch_area)    ORDER BY gid ASC) as f7
			,  array_agg(  COALESCE(reflectance_avg)    ORDER BY gid ASC) as f8
			,  array_agg(  COALESCE(nb_of_echo_avg)    ORDER BY gid ASC) as f9 
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
				AND proba_occurency >0.95
	) 
	SELECT  r.* 
	FROM array_agg,rc_random_forest_cross_valid_per_class_all_features(gid,f1,f2,f3,f4,f5,f6,f7,f8,f9,gt_class,proba,10,30) as r ; 