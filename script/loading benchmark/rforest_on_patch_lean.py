# -*- coding: utf-8 -*-
"""
Created on Sat Dec  6 17:01:05 2014

@author: remi

@TODO : 
in the function train_RForest_with_kfold we should keep all result proba for each class, this could be very intersting.

"""
  
import numpy as np ; #efficient arrays
import pandas as pd;   # data frame to do sql like operation

import sklearn
reload(sklearn)
from sklearn.ensemble import RandomForestClassifier ; #base lib
from sklearn import cross_validation, preprocessing ; #normalizing data, creating kfold validation 


def create_test_data(feature_number, data_size, class_list):
    """simple function to emulate input, gid is a unique int, other are features"""
 
    import random ; #used to chose a class randomly
      
    #create test vector    
    feature = np.random.random_sample((data_size,feature_number)) * 10 ; 
    gid = np.arange(13,data_size+13) ; 
    
    #create ground truth class vector : a 1,N vector containing randomly one of the possible class
    ground_truth_class = np.zeros(data_size); 
    for i,(not_used) in enumerate(ground_truth_class):
        ground_truth_class[i] = np.random.choice(class_list) ;  
        
    return gid, feature, ground_truth_class ; 
    
def create_label_equivalency(labels_name, labels_number):
    """we create an equivalency list between class name and class number""" 
    import numpy as np; 
    labels =  np.zeros(len(labels_name), dtype={'names':['class_id', 'class_name']\
        , 'formats':['i4','a10']})  ;   
    for i in np.arange(0,len(labels_name)):
        labels['class_id'][i] = labels_number[i]
        labels['class_name'][i] = labels_name[i]  
    return labels; 

def preprocess_data(X): 
    from sklearn import preprocessing ;
    
    scaler = preprocessing.StandardScaler(copy=False,with_std=False); 
    scaler.fit_transform(X) ;  
    #scaler.transform(Y);
    #scaler.transform(X);
    return scaler;
    
def train_RForest_with_kfold(i,train, test, gid,X,Y,weight,scaler,clf,result,feature_importances,learning_time,predicting_time ):
    import datetime; 
    import time;
   # creating data for train and test
    X_train, X_test, Y_train, Y_test, Weight_train, Weight_test = X[train],X[test], Y[train], Y[test], weight[train], weight[test] ; 
    #learning 
    
    time_temp = time.clock();
    print '         starting learning at \n\t\t\t\t%s' % datetime.datetime.now() ;
    clf.fit(X_train,Y_train,Weight_train) ; 
    learning_time = learning_time+  time.clock() - time_temp; 
    
    #predicting       
    print '         learning finished, starting prediction at \n\t\t\t\t%s' % datetime.datetime.now() ;
    time_temp = time.clock();
    tmp_prob = clf.predict(X_test) ;  
    predicting_time += time.clock() - time_temp; 
    print '      prediction finished at \n\t\t\t\t%s' % datetime.datetime.now() ;
    #grouping for score per class
    proba_class_chosen = np.column_stack( \
    (np.array(gid)[test],tmp_prob, Y_test,Weight_test    ) ) ; 
    
    #constructinig the result data frame    
    df = pd.DataFrame(proba_class_chosen, columns = ("gid","class_chosen","ground_truth_class" ,"weight")) ; 
    if (i==0): 
        result = result.append(df, ignore_index=True) ;
    else:
        #print 'entering here, df is : ', df
        result = result.append( df,ignore_index=True) ; 
    #plpy.notice("feature used, by importcy");
    #plpy.notice(clf.feature_importances_)
    #storing how important was each feature to make the prediction 
    feature_importances.append(clf.feature_importances_) ;
    return learning_time,predicting_time,result
  

def Rforest_learn_predict(gid, X, Y,weight, labels, k_folds, random_forest_trees ,plot_directory): 
    from sklearn.metrics import classification_report 
    import datetime;
    scaler =  preprocess_data(X); 
    
    #creating the random forest object
    clf = RandomForestClassifier(random_forest_trees, criterion="entropy" ,min_samples_leaf=20) ; 
    
    #cutting the set into 10 pieces, then propossing 10 partiion of 9(trainng)+1(test) data
    kf_total = cross_validation.KFold(len(X), n_folds = k_folds, shuffle = True, random_state = 4) ;
    result = pd.DataFrame() ;
    feature_importances = [] ;
    learning_time = 0.0 ;
    predicting_time = 0.0 ;
    
    
    for i ,(train, test)  in enumerate(kf_total) :  
        print '     workingg on kfold %s , %s' % (i+1,datetime.datetime.now())
        learning_time,predicting_time, result = train_RForest_with_kfold(i,train, test,gid,X,Y,weight,scaler,clf,result,feature_importances,learning_time,predicting_time) ;
      
    report = classification_report( result['ground_truth_class'],result['class_chosen'],target_names = labels)#,sample_weight=result['weight'])  ;
    
     
    return np.column_stack((result['gid']
        ,result['ground_truth_class'].astype(int)
        , result['class_chosen'].astype(int)
        , np.zeros(len(result['ground_truth_class'])) )),report,feature_importances,learning_time,predicting_time;
 
def RForest_learn_predict_pg(gids,feature_iar,gt_classes,weight,labels_name,class_list, k_folds,random_forest_ntree, plot_directory):
    """Compute random forest classifiers using feature_iar and gt_classes ground trhuth. Divide the data set into kfolds to perform the operation K times
    @param gids is a int[n]
    @param feature_iar is a float[m x n], where m is the number of feature, and the matrix is wirtten row by row
    @param gt_classes is a int[n] giving the ground truth class for each observation
    @param k_folds is a int describing in how much part we should split the data set
    @param random_forest_ntree how much tree in the frest?
    @param plot_directory is a string like '/tmp', describing the directory where to write the figures generated
    """
    
    #reshape input feature vector into feature matrix 
    feature_iar = np.array( feature_iar, dtype=np.float)
    feature = np.reshape(feature_iar,( len(gids),len(feature_iar)/len(gids) ) ) ; 
    gids = np.array(gids);
    gt_classes = np.array(gt_classes)
    #plpy.notice('toto') 
    feature[np.isnan(feature)]=0 ; 
    
    labels = create_label_equivalency(labels_name,class_list )
    weight_iar = np.array(weight)
    return Rforest_learn_predict(gids
        ,feature
        ,gt_classes
        ,weight_iar
        ,labels
        , k_folds
        , random_forest_ntree 
        ,plot_directory) ; 
    
def RForest_learn_predict_pg_test():
    #param 
    nfeature = 3
    n_obs = 1000 ; 
    class_list = [1,2,3,4,5,6,7]
    labels = ['FF1', 'FF2', 'FF3', 'FO2', 'FO3', 'LA6', 'NoC']
    k_folds = 10
    random_forest_ntree = 10;
    plot_directory = '/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/result_rforest/vosges';

    #creating input of function
    gids = np.arange(13,n_obs+13);
    feature_iar = np.random.rand(nfeature*n_obs)*10 ;
    gt_classes = np.zeros(n_obs); 
    for i,(not_used) in enumerate(gt_classes):
        gt_classes[i] = np.random.choice(class_list) ;
    
    #
    gids= [8736, 8737, 8738, 8739, 8742, 8743, 8744, 8746, 8748, 8749]
    feature_iar = [0.0, 0.0, 0.0, 0.0, 1.0, 28.0, 2.0, 593.17, 0.0, 2.0, 4.0, 0.0, 0.0, 1.0, 36.511, 1.0, 592.176, 7.52, 0.0, 0.0, 0.0, 0.0, 1.0, 46.0, 1.0, 598.33, 0.0, 4.0, 23.0, 91.0, 347.0, 1.0, 33.2, 1.0, 585.271, 22.89, 6.0, 36.0, 189.0, 517.0, 1.0, 15.42, 2.0, 616.146, 39.41, 7.0, 37.0, 171.0, 497.0, 1.0, 13.532, 2.0, 607.817, 46.73, 6.0, 33.0, 155.0, 360.0, 1.0, 14.62, 2.0, 596.008, 42.09, 3.0, 29.0, 99.0, 255.0, 1.0, 11.295, 2.0, 572.784, 45.55, 3.0, 30.0, 118.0, 274.0, 1.0, 12.154, 2.0, 517.455, 49.62, 3.0, 28.0, 110.0, 278.0, 0.99, 11.016, 2.0, 495.071, 50.03] ; 
    gt_classes =[4, 4, 4, 4, 3, 3, 3, 2, 1, 1] 
    labels_name = ['FF1', 'FF2', 'FF3', 'NoC']
    class_list =[1, 2, 3, 4]
    weight =  [0.25, 0.25, 0.25, 0.25, 0.3333, 0.3333, 0.3333, 1.0, 0.5, 0.5]
    random_forest_ntree = 10 ; 
      
    #launching function
    result = RForest_learn_predict_pg(gids,feature_iar,gt_classes,weight,labels_name,class_list,k_folds,random_forest_ntree, plot_directory)
    return result ;
    

#print RForest_learn_predict_pg_test()
  