# -*- coding: utf-8 -*-
"""
Created on Fri Dec 26 15:44:31 2014

@author: remi
"""


import psycopg2

def connect_to_base():
    conn = psycopg2.connect(  
        database='test_pointcloud'
        ,user='postgres'
        ,password='postgres'
        ,host='localhost'
        ,port='5433' ) ; 
    cur = conn.cursor()
    return conn, cur ;
    
def set_search_path(conn,cur):
    #setting the search path    
    cur.execute("""SET search_path to vosges_2011, ocs, benchmark_cassette_2013 , public;"""); 
    conn.commit(); 


def execute_querry(q,arg_list,conn,cur): 
    
    #print q % arg_list ;  
    cur.execute( q ,arg_list) 
    
    
def launch_rforest(gids,feature_iar,gt_classes,weight_iar,labels_name,class_list, k_folds,random_forest_ntree, plot_directory):
    import rforest_on_patch_lean as rf
     
    labels = rf.create_label_equivalency(labels_name,class_list ) 
    return rf.Rforest_learn_predict(gids
        ,feature_iar
        ,gt_classes
        ,weight_iar
        ,labels
        , k_folds
        , random_forest_ntree 
        ,plot_directory) ; 
        
         
    


def test_rforest():
    import numpy as np; 
    import datetime;  
    conn,cur = connect_to_base();
    set_search_path(conn,cur);
    
    q = """ WITH patch_to_use AS (
        SELECT lvp.gid 
            , substring(gt_classes[1] from 1 for 1) as sgt_class
            , gt_weight[1]
            , avg_intensity
            , avg_tot_return_number
            , avg_z
            , avg_height 
			,points_per_level
			,random() as rand
		FROM las_vosges_proxy AS lvp    , ocs.ground_truth_area_manual as gta
        WHERE ST_Intersects(gta.geom, lvp.geom)=true
			--gt_weight[1] > 0.9 AND
			AND points_per_level IS NOT NULL 
           --ORDER BY gid ASC
		--ORDER by rand -- , gid
		LIMIT %s
	)
	,count_per_class as (
		SELECT sgt_class, row_number() over(ORDER BY sgt_class ASC) AS n_class_id , count(*) AS  obs_per_class
		FROM  patch_to_use  
		GROUP BY sgt_class 
	) 
	--, array_agg AS (
		SELECT gid 
			,COALESCE(points_per_level[2],0) as ppl1
			,COALESCE(points_per_level[3],0) as ppl2
			,COALESCE(points_per_level[4],0) as ppl3
			,COALESCE(points_per_level[5],0) as ppl4
			,avg_intensity
			, avg_tot_return_number
			, avg_z
			, avg_height  
			,  cc.n_class_id::int  as gt_class
			,  round(1/(cc.obs_per_class*1.0),10)::float  AS weight
		FROM patch_to_use
			LEFT OUTER JOIN count_per_class AS cc ON (cc.sgt_class =  patch_to_use.sgt_class) 
       ORDER BY gid ASC;""" ;
    nrow = 526275
    labels = ['Forest','Land','Notforest'] ; 
    arg_list = [nrow] ; 
    execute_querry(q,arg_list, conn,cur );
    print 'querry executed %s ' % (datetime.datetime.now()); 
    idata = cur.fetchall() 
    print 'data feteched %s ' % (datetime.datetime.now()); 
    ncol = len(idata[0]) 
    idata_ar = np.reshape(idata, [ nrow,ncol])
    print 'data reshaped %s ' % (datetime.datetime.now()); 
    rforest_result = launch_rforest(
        gids = idata_ar[:,0]
        ,feature_iar =  idata_ar[:,1:ncol-2]
        ,gt_classes = idata_ar[:, ncol-2]
        ,weight_iar = idata_ar[:, ncol-1]
        ,labels_name = ['Forest','Land','Notforest']
        ,class_list = [1,2,3]
        , k_folds = 10
        ,random_forest_ntree = 100
        , plot_directory = [])
    print 'rforest finished %s ' % (datetime.datetime.now()); 
    result,report,feature_importancy,learning_time,predicting_time = rforest_result ; 
    print report;
    feature_importancy = np.around(np.mean(feature_importancy,axis =0),2) ; 
    print ' feature_importancy %s' % feature_importancy;
    print ' learning_time : %s' % learning_time;
    print ' predicting_time: %s ' % predicting_time; 
    print 'labels : %s' % labels
    cur.close()
    conn.close()
    
    print 'end of function %s ' % (datetime.datetime.now()); 
    
test_rforest()