# -*- coding: utf-8 -*-
"""
Created on Sat Dec  6 17:01:05 2014

@author: remi

@TODO : 
in the function train_RForest_with_kfold we should keep all result proba for each class, this could be very intersting.

"""
  
import numpy as np ; #efficient arrays
import pandas as pd;   # data frame to do sql like operation

from sklearn.ensemble import RandomForestClassifier ; #base lib
from sklearn import cross_validation,preprocessing ; #normalizing data, creating kfold validation



def create_test_data(feature_number, data_size, class_list):
    """simple function to emulate input, gid is a unique int, other are features"""
 
    import random ; #used to chose a class randomly
      
    #create test vector    
    feature = np.random.random_sample((data_size,feature_number)) * 10; 
    gid = np.arange(13,data_size+13); 
    
    #create ground truth class vector : a 1,N vector containing randomly one of the possible class
    ground_truth_class = np.zeros(data_size); 
    for i,(not_used) in enumerate(ground_truth_class):
        ground_truth_class[i] = np.random.choice(class_list) ;  
        
    return gid, feature, ground_truth_class ; 
    
def create_label_equivalency():
    """we create an equivalency list between class name and class number"""
    label_list = [(0,"undef" ),(1,"other"),(2,"ground")\
        ,(3,"object"),(4,"building"),(5,"vegetation")] ;
        
    labels=  np.zeros(6, dtype={'names':['class_id', 'class_name']\
        , 'formats':['i4','a10']})  ;  
    labels[:] =  label_list  
    return labels; 

def preprocess_data(X): 
    from sklearn import preprocessing ; 
    scaler = preprocessing.StandardScaler(copy=False,with_std=False); 
    scaler.fit_transform(X) ;  
    #scaler.transform(Y);
    #scaler.transform(X);
    return scaler;
    
def train_RForest_with_kfold(i,train, test, gid,X,Y,scaler,clf,result,feature_importances):
   # creating data for train and test
    X_train, X_test, Y_train, Y_test = X[train],X[test], Y[train], Y[test] ; 
    #learning
    clf.fit(X_train,Y_train) ; 
    #predicting    
    tmp_prob = clf.predict_proba(X_test) ; 
    
    #finding for each prediction the class that has more proba
    max_ix = np.argmax(tmp_prob,axis=1) ; #max proba 1D index
    indice_of_chosen_class =  np.unravel_index(max_ix, tmp_prob.shape)[1].T #max proba real index
    chosen_class = clf.classes_[indice_of_chosen_class] # extracct the class number ith index  from the class list 
    
    #getting the highest proba value , couild be avoided in theory
    max_values = np.amax(tmp_prob,axis=1);

    #grouping for score per class
    proba_class_chosen = np.column_stack( \
    (max_values,chosen_class, chosen_class == Y_test,Y_test ,np.array(gid)[test]   ) ) ; 
    
    #constructinig the result data frame    
    df = pd.DataFrame(proba_class_chosen, columns = ("proba_chosen","class_chosen","is_correct","ground_truth_class" ,"gid")) ; 
    if (i==0): 
        result = result.append(df, ignore_index=True) ;
    else:
        #print 'entering here, df is : ', df
        result = result.append( df,ignore_index=True) ; 
    #plpy.notice("feature used, by importcy");
    #plpy.notice(clf.feature_importances_)
    #storing how important was each feature to make the prediction 
    feature_importances.append(clf.feature_importances_) ;
    return result

def computing_success_per_class(result,classes_,plot_directory): 
    grouped_result = result.groupby(["class_chosen"])   
    mean_result  = grouped_result.aggregate(np.mean) ;   
    grouped_proba = grouped_result['proba_chosen',"is_correct","ground_truth_class"]
    for name, group in grouped_proba :
        g2 = group.sort(columns="proba_chosen",ascending=False )
        g2['is_wrong'] =g2.is_correct==False ; 
        g2['new_index'] =  np.arange(1, len(g2)+1 ) *1.0 /len(g2); 
    
        g2['cum_sum'] =g2.is_correct.cumsum() 
        g2['result_prediction'] =100*g2.cum_sum/( g2.new_index*len(g2) )
        g2['x_axis'] =1- g2['proba_chosen']  ;
        
        if len(plot_directory) != 0:#empty
            plot_result_per_class(g2,name,classes_,plot_directory);
            

def plot_result_per_class(g2,name,classes_,plot_directory): 
    import matplotlib.pyplot as plt
    matplotlib.use('Agg') ;
    plt.clf()
    plt.cla()
    plt.close()  
    plot = g2.plot(x='x_axis', y= 'result_prediction',ylim=[-10,110], title="using prediction by descending confidence for class "+str(int(name))  )
    labx = plt.xlabel("1-minimal_confidence")
    laby = plt.ylabel("precision_of_prediction")
    plt.axhline(y=g2['result_prediction'].mean(), label='mean_line')
    #plt.plot(x=g2['x_axis'],y=100*g2['new_index']/len(g2))
    #title = title("using prediction by descending confidence")
    
    save  = plt.savefig(plot_directory
        +'/test_output_all_feature_'
        # + str(int( np.amax(clf.classes_)))
        # +'_against_all_'
        +str(int(name)) 
        +'_.jpg') ; 
    
    plt.clf()
    plt.cla()
    plt.close() 

def print_confusion_matrix(result, labels, classes_,plot_directory):
    classes = classes_.astype(int)
    import matplotlib.pyplot as plt
    matplotlib.use('Agg') ;
    from sklearn.metrics import confusion_matrix ; #evaluating confusion matrix
    
    plt.clf()
    plt.close() ;
    plt.cla ; 
    
    cm = confusion_matrix(result['ground_truth_class'], result['class_chosen']) 
    cm = cm * 1.0 ;
    preprocessing.normalize(cm, norm='l1', axis=0,copy=False)
    #plpy.notice(cm); 
    fig = plt.figure()
    ax = fig.add_subplot(111)
    cax = ax.matshow(cm,cmap = plt.get_cmap('YlOrBr'),vmin=0, vmax=1) 
    plt.title('Confusion matrix of the classifier')
    fig.colorbar(cax, cmap = plt.get_cmap('YlOrBr') )
    
    ax.set_xticklabels([''] + list(labels[classes]['class_name']) )
    ax.set_yticklabels([''] + list(labels[classes]['class_name']) )
    plt.xlabel('Predicted')
    plt.ylabel('True') 
    for i, cas in enumerate(cm):
    	for j, c in enumerate(cas):
    		if c>0:
    			plt.text(j-.2, i+.2, str(round(c, 3)), fontsize=12)
    plt.savefig(
        plot_directory
        + '/test_output_all_feature_confusion_matrix_.png'
        )
    plt.clf()
    plt.cla()
    plt.close() 

def Rforest_learn_predict(gid, X, Y,labels, k_folds, random_forest_trees ,plot_directory): 
 
    scaler =  preprocess_data(X); 
    
    #creating the random forest object
    clf = RandomForestClassifier(random_forest_trees, criterion="entropy" ,min_samples_leaf=20) ; 
    
    #cutting the set into 10 pieces, then propossing 10 partiion of 9(trainng)+1(test) data
    kf_total = cross_validation.KFold(len(X), n_folds = k_folds, indices = True, shuffle = True, random_state = 4) ;
    result = pd.DataFrame() ;
    feature_importances = [] ;
    for i ,(train, test)  in enumerate(kf_total) :  
        result = train_RForest_with_kfold(i,train, test, gid,X,Y,scaler,clf,result,feature_importances) ;
    

    #plotting the result for each class
    computing_success_per_class(result,clf.classes_,plot_directory);
     
    #print the confusion matrix
    if len(plot_directory)!=0:
        print_confusion_matrix(result, labels, clf.classes_,plot_directory) 
    
    return np.column_stack((result['gid']
        ,result['ground_truth_class'].astype(int)
        , result['class_chosen'].astype(int)
        , result['proba_chosen']  )) ;
    
def Rforest_learn_predict_test():
        
    ############
    #parameter :
    k_folds = 10
    random_forest_trees = 30
    plot_directory =  '/media/sf_perso_PROJETS/lod';
    labels = create_label_equivalency() ;
    class_list = [2,3,5] ;
    #############
     
    
    gid, X, Y  = create_test_data(3, 100,class_list) ;    
    
    result = Rforest_learn_predict(gid, X, Y,labels,class_list, k_folds, random_forest_trees ,plot_directory);
    print result ;

def RForest_learn_predict_pg(gids,feature_iar,gt_classes,labels, k_folds,random_forest_ntree, plot_directory):
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
    print feature.dtype
    feature[np.isnan(feature)]=0 ; 
    return Rforest_learn_predict(gids
        ,feature
        ,gt_classes
        ,labels
        , k_folds
        , random_forest_ntree 
        ,plot_directory) ; 
    
def RForest_learn_predict_pg_test():
    #param 
    nfeature = 3
    n_obs = 1000 ; 
    class_list = [2,4,5]
    k_folds = 10
    random_forest_ntree = 10;
    plot_directory = [];
    labels = create_label_equivalency() ;
    #creating input of function
    gids = np.arange(13,n_obs+13);
    feature_iar = np.random.rand(nfeature*n_obs)*10 ;
    gt_classes = np.zeros(n_obs); 
    for i,(not_used) in enumerate(gt_classes):
        gt_classes[i] = np.random.choice(class_list) ;
    
    #
    gids=  [3641, 3642, 3643, 3644, 3645, 3646, 3647, 3648, 3649, 7207, 249840, 249844, 249873, 249874, 249899, 249932, 249941, 249965, 249983, 249996]; 
    feature_iar =  [4.0, 16.0, 64.0, 264.0, 4.0, 1.0, -2.212, 0.105, -4.323, 1.0, 4.0, 16.0, 64.0, 258.0, 4.0, 1.0, -2.191, 0.103, -4.5, 1.0, 4.0, 16.0, 64.0, 256.0, 4.0, 1.0, -2.111, 0.102, -4.061, 1.0, 4.0, 16.0, 64.0, 258.0, 4.0, 1.0, -2.089, 0.105, -3.601, 1.0, 4.0, 16.0, 64.0, 253.0, 4.0, 0.999, -2.082, 0.103, -3.959, 1.0, 4.0, 16.0, 64.0, 256.0, 4.0, 0.999, -2.068, 0.107, -3.561, 1.0, 6.0, 21.0, 79.0, 299.0, 4.0, 0.999, -2.058, 0.131, -3.879, 1.0, 4.0, 16.0, 64.0, 264.0, 4.0, 0.999, -2.045, 0.115, -4.353, 1.0, 6.0, 19.0, 89.0, 290.0, 4.0, 0.999, -2.036, 0.133, -4.709, 1.0, 2.0, 12.0, 30.0, None, 4.0, 0.998, -0.52, 0.06, -3.252, 1.0, 6.0, 17.0, 9.0, None, 5.0, 0.869, 4.314, 0.449, -11.238, 1.114, 3.0, 11.0, 9.0, None, 5.0, 0.96, 6.665, 0.169, -9.533, 1.119, 4.0, 7.0, 2.0, None, 5.0, 0.602, 5.788, 0.145, -14.108, 2.0, 8.0, 9.0, 4.0, None, 5.0, 0.992, 7.096, 0.359, -13.102, 2.033, 6.0, 10.0, 3.0, None, 5.0, 0.855, 2.142, 0.302, -14.109, 2.476, 8.0, 27.0, 73.0, 115.0, 5.0, 0.996, 3.131, 0.719, -8.001, 1.082, 7.0, 24.0, 26.0, 17.0, 5.0, 0.985, 3.155, 0.422, -10.603, 1.124, 7.0, 15.0, 14.0, 7.0, 5.0, 0.933, 5.888, 0.276, -12.079, 1.235, 3.0, 12.0, 28.0, 24.0, 5.0, 0.417, 2.575, 0.395, -10.184, 1.077, 6.0, 18.0, 11.0, None, 5.0, 0.807, -0.163, 0.479, -11.312, 1.704] ; 
    gt_classes =[4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5] ;  
    random_forest_ntree = 10 ; 
    
    #launching function
    result = RForest_learn_predict_pg(gids,feature_iar,gt_classes,labels,k_folds,random_forest_ntree, plot_directory)
    print result;
    return result ;
    
    
RForest_learn_predict_pg_test() 