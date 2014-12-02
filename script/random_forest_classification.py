# -*- coding: utf-8 -*-
"""
Created on Sun Nov 30 19:09:22 2014

@author: remi
"""

# This script allows to use scikit learn with random forest
#we have an input vector with ground truth and x 1D descriptors
# we want to find if the descriptors are well adapted to classify classes, and for which classes it works ok.
import numpy as np ; 

from sklearn.ensemble import RandomForestClassifier ; 
from sklearn.tree import DecisionTreeClassifier; 
from sklearn import cross_validation ; 
#from sklearn import metrics ;  
#from sklearn.feature_selection import RFECV ; 
import pandas as pd; 
from sklearn import preprocessing;
from sklearn.metrics import confusion_matrix

import matplotlib as mpl ;
import matplotlib.pyplot as plt 
 

#parameters of the random forest
n_estimator = 10 ;  
    
f1 = np.array([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]);
f2 = np.array([4,6,8,4,4,4,2,4,4,4,4,4,4,4,4,4,2,3,4,4,4,4,4,4,4,4,4,8,5,8]);
f3 = np.array([16,19,24,24,24,13,7,15,15,16,14,16,16,16,14,12,11,12,17,16,16,13,16,15,13,13,17,31,32,28]);
f4 = np.array([38,49,70,45,40,27,57,47,53,57,48,53,49,61,49,49,51,38,34,53,63,46,56,42,36,33,70,90,91,93]);
gid=  np.array([49,50,56,179,180,188,227,230,234,244,245,248,255,260,262,266,267,269,271,274,281,287,288,289,290,291,292,301,302,303]) ; 
gt_class = np.array([4,4,3,4,4,4,4,2,4,2,4,4,4,2,4,4,4,2,2,4,2,4,4,4,2,2,2,4,4,4]) ;
proba = np.array([1,1,1,1,1,1,1,1,1,1,1,1,1,0.935135135135135,1,1,1,0.785046728971963,0.884297520661157,1,1,1,1,1,0.866666666666667,0.982456140350877,0.717592592592593,0.934689507494647,0.931665062560154,0.918892185954501]) ; 

X = np.column_stack((f1,f2,f3,f4)); 
Y = np.array( gt_class) ; 

clf = RandomForestClassifier(n_estimator, verbose=0,criterion="entropy") ; 
clf = DecisionTreeClassifier(criterion='entropy', splitter='best', max_depth=None, min_samples_split=10, min_samples_leaf=1,   max_features=None, random_state=4 ) ; 
#clf = clf.fit(X,Y ) ; 
#  clf = []
result = []
scaler = preprocessing.StandardScaler().fit(X) ;  


kf_total = cross_validation.KFold(len(X), n_folds = 3, indices = True, shuffle = True, random_state = 4) ;
result = pd.DataFrame() ; 
for i ,(train, test)  in enumerate(kf_total) :  
    #print train , test
    X_train, X_test, Y_train, Y_test = X[train],X[test], Y[train], Y[test] ;  
    tmp = clf.fit(scaler.transform(X_train), Y_train ) ; 
    tmp_prob = clf.predict_proba(scaler.transform(X_test) );
    #tmp_prob ;
    #finding the result per class
    max_ix = np.argmax(tmp_prob,axis=1) ; 
    indice_of_chosen_class =  np.unravel_index(max_ix, tmp_prob.shape)[1].T 
    chosen_class = clf.classes_[indice_of_chosen_class]
    #chosen_class == Y_test ;
    
    #getting the highest value 
    max_values = np.amax(tmp_prob,axis=1);

    #grouping for score per class
    proba_class_chosen = np.column_stack( (max_values,chosen_class, chosen_class == Y_test,Y_test )) ; 
    df = pd.DataFrame(proba_class_chosen, columns = ("proba_chosen","class_chosen","is_correct","ground_truth_class") ) ;
    #   group_by_class = df.groupby(["class_chosen"])    
    #    #print group_by_class["class_chosen","is_correct"] 
    #    tmp_result = group_by_class["is_correct"].aggregate(np.mean) 
    #print i ; 
    if i == 0 :
        result = df;
    else:
        result = result.append( df,ignore_index=True) ;
    #max_values = tmp_prob[:,tmp_max]
    #    print max_values ;
    #    print "only high enough values"
    #    print tmp_prob[ np.amax(tmp_prob,axis=1)>=0.9 ]
    #    print X_test
        
    #    cm = confusion_matrix(Y_test, chosen_class)
    #    print(cm)
    #    plt.matshow(cm)
    #    plt.title('Confusion matrix')
    #    plt.colorbar()
    #    plt.ylabel('True label')
    #    plt.xlabel('Predicted label')
    #    plt.savefig('/tmp/foo.png' )
    #plt.show()

grouped_result = result.groupby(["class_chosen"])  

grouped_proba = grouped_result['proba_chosen',"is_correct","ground_truth_class"]
for name, group in grouped_proba :
    #print(name)
    #print(group.sort(columns="proba_chosen" ).cumsum() )
    g2 = group.sort(columns="proba_chosen",ascending=False )
    g2['is_wrong'] =g2.is_correct==False ;
    np.arange(1, len(g2) )
    g2['new_index'] =  np.arange(1, len(g2)+1 ) ; 
    
    g2['cum_sum'] =g2.is_correct.cumsum() 
    g2['result_prediction'] = 100*g2.cum_sum/ g2.new_index
    plot = g2.plot(x='new_index', y= 'result_prediction')
    xlabel("number_of_observations")
    ylabel("precision_of_prediction")
    title("using prediction by descending confidence")
    ylim([-10,110]) 
    savefig('/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/result_rforest/test_output_'+str(name) +'_.png')
    close() 

g2[['new_index','proba_chosen','is_correct','result_prediction']]
plot = g2.plot(x='new_index', y= 'result_prediction')
xlabel("number_of_observations")
ylabel("precision_of_prediction")
title("using prediction by descending confidence")
ylim([0,100]) 
savefig('/tmp/test_output.pdf')
close();

 

labels=  np.zeros(6, dtype={'names':['class_id', 'class_name'], 'formats':['i4','a10']}) 
labels[clf.classes_]['class_name']
labels[:] =  [(0,"undef" ),(1,"other"),(2,"ground"),(3,"object"),(4,"building"),(5,"vegetation")] 
labels['class_name']

labels_df = pd.DataFrame.from_records(labels, index = 'class_id' ) ; 
labels_gt = labels_df.rename(columns={'class_name': 'ground_truth_class_name'} ) 
labels_chosen = labels_df.rename(columns={'class_name': 'chosen_class_name'} )
g2 = g2.join(labels_gt, on = 'ground_truth_class')
g2 = g2.join(labels_chosen, on = 'class_chosen')
 
 
classes_used = np.array(clf.classes_,dtype=[('class_id', np.int_) ])
 type(clf.classes_)
 
classes_used_df = pd.DataFrame(clf.classes_ ) 
classes_used_df.columns = ['class_id'] ;
classes_used_df = classes_used_df.set_index('class_id')

cm = confusion_matrix(g2['ground_truth_class'], g2['class_chosen']) 
fig = plt.figure()
ax = fig.add_subplot(111)
cax = ax.matshow(cm)
plt.title('Confusion matrix of the classifier')
fig.colorbar(cax)
ax.set_xticklabels([''] + list(labels[clf.classes_]['class_name']) )
ax.set_yticklabels([''] + list(labels[clf.classes_]['class_name']) )
plt.xlabel('Predicted')
plt.ylabel('True')
fig.show()
plt.savefig('/media/sf_E_RemiCura/PROJETS/point_cloud/PC_in_DB/LOD_ordering_for_patches_of_points/result_rforest/test_output_confusion_matrix_.png')
plt.close();

cm = confusion_matrix(y_test, pred, labels)
print(cm)

cax = ax.matshow(cm)
pl.title('Confusion matrix of the classifier')
fig.colorbar(cax)
ax.set_xticklabels([''] + labels)
ax.set_yticklabels([''] + labels)
pl.xlabel('Predicted')
pl.ylabel('True')
pl.show()

 
 
print group.sort(columns="proba_chosen",ascending=False ); 
.rank(method='min')
mean_result  = grouped_result.aggregate(np.mean) ;   

np.column_stack((mean_result.to_records(index=True)["class_chosen"],mean_result.to_records(index=True)["is_correct"] ))
 


scores = cross_validation.cross_val_score(clf, X, Y, cv=kf_total, n_jobs = -1) ;
mean(scores)
 
 
 rfecv = RFECV(estimator=clf,
               step = 1
               ,cv=kf_total )
rfecv.fit(X,Y)





