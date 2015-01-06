##!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Created on Wed Dec 10 16:59:09 2014

@author: remi
"""
import math
import numpy as np; 
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier ;
from sklearn.cross_validation import cross_val_score,KFold
from sklearn.metrics import classification_report
from sklearn.metrics import confusion_matrix
import UnbalancedDataset;

def pg_to_np(gid, feature, gt_weight_vect):
    gid_arr  = np.array(gid,dtype=int);
    feature_arr =  np.reshape(np.array(feature), (-1, len(feature)/len(gid_arr)) ) ; 
    gt_weight_vect_arr =  np.reshape(np.array(gt_weight_vect), (-1, len(gt_weight_vect)/len(gid_arr)) ) ; 
    return gid_arr, feature_arr,gt_weight_vect_arr; 

def rf_regressor_pg(gid, feature, gt_weight_vect):
    n_estimators = 200 ; 
    k_folds = 10 ; 
    #convert input to corerctly shaped umpy array
    gid_arr, X,Y_tmp = pg_to_np(gid, feature, gt_weight_vect); 
   
    #preprocess : scale
    from sklearn import preprocessing ; 
    scaler = preprocessing.StandardScaler(copy=False,with_std=False); 
    scaler.fit_transform(X) ; 
    
    #take care of labels
    #create rforest
    #Y = np.ceil(Y_tmp).astype(int) 
    clf = RandomForestClassifier(n_estimators, criterion='entropy', min_samples_split=20 , compute_importances=True)
    Y = Y_tmp
    clf =  RandomForestRegressor(n_estimators, criterion='mse',  min_samples_split=2 , random_state=4  )
    
    kf_total =  KFold(len(X), n_folds = k_folds, indices = True, shuffle = True, random_state = 4) ;    
    
    reports = [];
    for i ,(train, test)  in enumerate(kf_total) :
        X_train, X_test, Y_train, Y_test = X[train],X[test], Y[train], Y[test] ;   
        #learning
        clf.fit(X_train,Y_train) ; 
        #predicting    
        tmp_prob = clf.predict(X_test) ;
        print tmp_prob, Y_test
        print abs(tmp_prob-Y_test),axis=0)#mean for every class using line where truth is not null
        #print 'report : ',  classification_report(Y_test, tmp_prob  ) ; 
        #report = classification_report(Y_test, tmp_prob )#,target_names = ["building","tree","road","sidewalk","4+ wheelers","unclassified","curb","punctual object","other object","2 wheelers","other ground","pedestrian"]  )
        #print report
        #reports.append(report ) ; 
        error_mat = error_matrix(tmp_prob,Y_test)
        reports.append(str(error_mat))
    
    #print 'cross val score  ',cross_val_score(clf,X ,Y ,cv=5, scoring="recall" )
    
    return  reports
    
def error_matrix(Predict, GTruth):
    err_mat = np.zeros([Predict.shape[1],Predict.shape[1]]) 
    n_copy = np.zeros(Predict.shape[1])+1; 
    for i in np.arange(0,Predict.shape[0]):#loop on observations
        for j in np.arange(0,Predict.shape[1]):#loop on classes
            if GTruth[i,j]!=0:
                err_mat[j]+= np.abs(GTruth[i,:]-Predict[i,:]);
                n_copy[j]+=n_copy[j]; 
    for k in np.arange(0,Predict.shape[1]):
        err_mat[k,:] /=  n_copy[k]
    return np.around(err_mat,3)*100 ;
        
def rf_regressor_pg_test():
    #emulating input
    gid =  [964, 1062, 1063, 1064, 1066, 1072, 1074, 1076, 1139, 1140, 1173, 1174, 1175, 1176, 1177, 1181, 1183, 1254, 1257, 1261, 1277, 1278, 1285, 1286, 1291, 1292, 1293, 1294, 1295, 1296, 1300, 1302, 1304, 1375, 1378, 1379, 1380, 1381, 1382, 1386]
    feature = [7.0, 19.0, 70.0, 6.0, 28.0, 123.0, 6.0, 23.0, 101.0, 6.0, 24.0, 102.0, 6.0, 18.0, 82.0, 6.0, 19.0, 73.0, 7.0, 19.0, 74.0, 8.0, 19.0, 73.0, 4.0, 16.0, 72.0, 8.0, 23.0, 102.0, 6.0, 32.0, 112.0, 6.0, 28.0, 140.0, 7.0, 30.0, 118.0, 6.0, 28.0, 98.0, 6.0, 24.0, 89.0, 5.0, 27.0, 72.0, 5.0, 25.0, 70.0, 3.0, 12.0, 36.0, 5.0, 16.0, 37.0, 4.0, 19.0, 69.0, 4.0, 9.0, 15.0, 4.0, 6.0, 0.0, 3.0, 7.0, 17.0, 5.0, 23.0, 82.0, 6.0, 30.0, 104.0, 6.0, 25.0, 111.0, 6.0, 26.0, 123.0, 6.0, 24.0, 109.0, 7.0, 22.0, 83.0, 5.0, 18.0, 83.0, 5.0, 26.0, 90.0, 5.0, 26.0, 82.0, 5.0, 27.0, 75.0, 4.0, 13.0, 26.0, 4.0, 13.0, 36.0, 4.0, 24.0, 96.0, 4.0, 21.0, 87.0, 4.0, 16.0, 44.0, 6.0, 22.0, 77.0, 4.0, 25.0, 73.0]
    gt_weight_vect =[0.0, 0.0, 0.51642, 0.29424, 0.0, 0.0, 0.15181, 0.03753, 0.0, 0.0, 0.0, 0.0, 0.33141, 0.0, 0.01354, 0.55014, 0.0, 0.0, 0.07061, 0.03429, 0.0, 0.0, 0.0, 0.0, 0.14116, 0.0, 0.06088, 0.70034, 0.0, 0.0, 0.09762, 0.0, 0.0, 0.0, 0.0, 0.0, 0.17827, 0.0, 0.10442, 0.60833, 0.0, 0.0, 0.08718, 0.0218, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.24379, 0.61297, 0.0, 0.0, 0.09666, 0.04658, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.57751, 0.30605, 0.0, 0.0, 0.09415, 0.02229, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.68076, 0.21304, 0.0, 0.0, 0.08394, 0.02226, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.78124, 0.12556, 0.0, 0.0, 0.06797, 0.02523, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.67638, 0.09951, 0.0, 0.0, 0.19094, 0.0, 0.0, 0.02994, 0.0, 0.0, 0.0, 0.0, 0.43761, 0.08718, 0.0, 0.0, 0.10342, 0.0, 0.0, 0.37179, 0.0, 0.0, 0.41179, 0.0, 0.0143, 0.46822, 0.0, 0.0, 0.08195, 0.02374, 0.0, 0.0, 0.0, 0.0, 0.41485, 0.0, 0.05645, 0.44156, 0.0, 0.0, 0.08714, 0.0, 0.0, 0.0, 0.0, 0.0, 0.39257, 0.0, 0.08803, 0.41884, 0.0, 0.0, 0.07619, 0.02437, 0.0, 0.0, 0.0, 0.0, 0.27638, 0.0, 0.15282, 0.49645, 0.0, 0.0, 0.07436, 0.0, 0.0, 0.0, 0.0, 0.0, 0.11788, 0.0, 0.23341, 0.60088, 0.0, 0.0, 0.04783, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.50657, 0.41576, 0.0, 0.0, 0.02927, 0.04841, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.62142, 0.31196, 0.0, 0.0, 0.03009, 0.03653, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.60429, 0.20663, 0.02729, 0.0, 0.16179, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.39209, 0.43657, 0.01153, 0.0, 0.1598, 0.0, 0.0, 0.0, 0.0, 0.0, 0.51833, 0.0, 0.06833, 0.31333, 0.0, 0.01833, 0.08083, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.01923, 0.01538, 0.0, 0.05385, 0.0, 0.0, 0.0, 0.91154, 0.0, 0.0, 0.0, 0.0, 0.01786, 0.30357, 0.0, 0.04762, 0.0, 0.0, 0.0, 0.63095, 0.0, 0.0, 0.0, 0.0, 0.02135, 0.47687, 0.0, 0.02847, 0.0, 0.0, 0.0, 0.47331, 0.0, 0.0, 0.0, 0.0, 0.90162, 0.04476, 0.0, 0.0182, 0.0, 0.0, 0.0, 0.03542, 0.0, 0.37955, 0.0, 0.01306, 0.51601, 0.0, 0.0, 0.05999, 0.0314, 0.0, 0.0, 0.0, 0.0, 0.37617, 0.0, 0.04812, 0.51061, 0.0, 0.0, 0.0651, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35184, 0.0, 0.08327, 0.47293, 0.0, 0.0, 0.07265, 0.01932, 0.0, 0.0, 0.0, 0.0, 0.28551, 0.0, 0.1378, 0.5133, 0.0, 0.0, 0.06338, 0.0, 0.0, 0.0, 0.0, 0.0, 0.06232, 0.0, 0.22947, 0.60843, 0.0, 0.0, 0.07385, 0.02594, 0.0, 0.0, 0.0, 0.0, 0.02925, 0.0, 0.30485, 0.62548, 0.0, 0.0, 0.04042, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.51966, 0.35382, 0.0, 0.0, 0.07184, 0.05468, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.62795, 0.24804, 0.0, 0.0, 0.07134, 0.05268, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.76494, 0.16434, 0.0, 0.0, 0.02158, 0.04914, 0.0, 0.0, 0.0, 0.0, 0.09274, 0.0, 0.47984, 0.10081, 0.0, 0.0, 0.18952, 0.0, 0.0, 0.1371, 0.0, 0.0, 0.01836, 0.0, 0.22371, 0.53088, 0.0, 0.11352, 0.11185, 0.0, 0.0, 0.0, 0.0, 0.0, 0.29056, 0.0, 0.18402, 0.42228, 0.0, 0.0, 0.10315, 0.0, 0.0, 0.0, 0.0, 0.0, 0.18015, 0.0, 0.16753, 0.52209, 0.0, 0.0, 0.13024, 0.0, 0.0, 0.0, 0.0, 0.0, 0.30992, 0.0, 0.08953, 0.49862, 0.0, 0.0, 0.09366, 0.0, 0.0, 0.0, 0.0, 0.0, 0.30118, 0.0, 0.09918, 0.4222, 0.0, 0.0, 0.17288, 0.0, 0.0, 0.0, 0.0, 0.0, 0.64986, 0.0, 0.0, 0.2569, 0.01998, 0.07326, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
     
    #feature = np.random.rand(3*10);
    #gt_weight_vect = np.ceil(np.random.rand(12*10));
    #launching rforest regressor
     
    
    return rf_regressor_pg(gid, feature, gt_weight_vect);

rf_regressor_pg_test()

#r1 = np.random.random((5,3));
##r1 /= np.sqrt((r1 ** 2).sum(-1))[..., np.newaxis] 
#r2 = np.random.random((5,3)); 
##r2 /= np.sqrt((r2 ** 2).sum(-1))[..., np.newaxis] 
#np.power(r1-r2,2)
#np.mean(np.mean(np.power(r1-r2,2),axis = 1) )
