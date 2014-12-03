# -*- coding: utf-8 -*-
"""
Created on Tue Dec  2 22:08:22 2014

@author: remi
"""

#trying to order points by octree with python
from numpy import random, sqrt
from sklearn import preprocessing  
import matplotlib.pyplot as plt

#defining a dummy entry :a random 3D pointcloud
pointcloud = random.rand(16*16,2);
index = np.arange(1,16*16+1)

#parameters
tot_level = 3 ;

#centering data so that leftmost pint is 0 abs, bottom most point is 0

pointcloud[:,0] = pointcloud[:,0]- np.amin(pointcloud[:,0]); 
pointcloud[:,1] = pointcloud[:,1]- np.amin(pointcloud[:,1]); 

#finding the max scaling, in X, Y or Z
max_r = max(np.amax(pointcloud[:,0])-np.amin(pointcloud[:,0]), np.amax(pointcloud[:,1])-np.amin(pointcloud[:,1]))

#dividing so max scale is 0 . Now the point cloud is between 0,1 and  0,1
pointcloud = pointcloud/ max_r ; 

#we have to trick a litlle, so has that for level 3 for instance, all value are between 0 and 7 included, but not reaching 8.

pointcloud_int =  np.trunc(abs((pointcloud*pow(2,tot_level)-0.0001))).astype(int)


plt.plot(pointcloud[:,0],pointcloud[:,1], 'ro') ; 
plt.plot(pointcloud_int[:,0],pointcloud_int[:,1], 'ro') ;
plt.axis([-1, 8, -1, 8]) ;
plt.show() ; 
plt.close('all');

result_point = pointcloud_int[rec_ar[:,0]]
plt.plot(result_point[:,0],result_point[:,1], 'ro') ;


rec_ar = np.array(rec) 
piv_ar = np.array(piv) 
plt.plot(piv_ar[:,0], piv_ar[:,1], 'ro') ;


np.binary_repr(1)
def bin(s):
    return str(s) if s<=1 else bin(s>>1) + str(s&1)

def testBit(int_type, offset):
    mask = 1 << offset
    return( (int_type & mask)>0 )
testBit(8,1)
pointcloud_bin = np.binary_repr(pointcloud_int)

funcs = [lambda x: np.binary_repr(x)]
apply_vectorized = np.vectorize(lambda f, x: f(x))
pointcloud_bin = apply_vectorized(funcs, pointcloud_int)

pointcloud_int >> (tot_level-1) ; 
#np.binary_repr(8)
( ((pointcloud_int >> 1 ) << 1) ) >> (tot_level-1) ; 
testBit(pointcloud_int[:,1],3)
#cut the input point cloud into 8 based on l bit value starting form right to left
point_cloud_0_0_mask = np.logical_and((testBit(pointcloud_int[:,0],2)==0) , (testBit(pointcloud_int[:,1],2)==0) ) ; 
pivot = np.array([pow(2,tot_level-1),pow(2,tot_level-1)])
pointcloud_centered = pointcloud_int - pivot

#coordinate to work : 

toto = np.array([1,2,3])
testBit(toto,1)

(pointcloud_int >>1 )>>5

pow(2,4) 
1<<4
    #

# level 0 
result = list() ; 
pointcloud_int ;
index
pivot
cur_lev = 0 
rec = []; 
 

#find the 0 level point
min_point = np.argmin(np.sum(np.abs(pointcloud_int - pivot ),axis=1))
result.append(list((index[min_point],cur_lev)))
#compute the 4 sub parts
for b_x in list((0,1))  :
    for b_y in list((0,1)) :
        #looping on all 4 sub parts
        print b_x, b_y
        rec.append (np.logical_and(
            (testBit(pointcloud_int[:,0],2)>0)==b_x
            ,(testBit(pointcloud_int[:,1],2)>0)==b_y
        )
        )
        testBit(pointcloud_int[:,0],2)
        print (testBit(pointcloud_int[:,0],2)>0==b_x) ;
        print (testBit(pointcloud_int[:,1],2)>0==b_y) ;
        rec[b_x,b_y] = np.logical_and((testBit(pointcloud_int[:,0],2)>0==b_x) 
        ,(testBit(pointcloud_int[:,1],2)>0==b_y) ) 
        print rec
np.binary_repr(pointcloud_int[:,0] ) 
#givne a point cloud
#compute the closest to center


def recursive_octree_ordering(point_array,index_array, center_point, level,tot_level, result,piv):
    #importing necessary lib
    import numpy as np;
    
    #print for debug
    #    print '\n\n working on level : '+str(level); 
    #    print 'input points: \n\t',point_array ; 
    #    print 'index_array : \n\t',index_array;
    #    print 'center_point : \n\t',center_point;
    #    print 'level : \n\t',level;
    #    print 'tot_level : \n\t',tot_level;
    #    print 'result : \n\t',result;
    #stopping condition : no points:
     
    if len(point_array) == 0|level<=2:
        return;
    #updatig level;
    sub_part_level = level+1 ;
    
    print 'level ',level,' , points remaining : ',len(point_array) ;
    print center_point;
    piv.append(center_point); 
       
    
    #find the closest point to pivot
    min_point = np.argmin(np.sum(np.abs(point_array - center_point ),axis=1))
    result.append(list((index_array[min_point],level))) ;  
    #removing the found point from the array of points 
    #np.delete(point_array, min_point, axis=0) ;
    #np.delete(index_array, min_point, axis=0) ;
    
    #stopping if it remains only one pioint : we won't divide further, same if we have reached max depth
    if (len(point_array) ==1 )|(level >= tot_level):
        return;
    #compute the 4 sub parts
    for b_x in list((0,1))  :
        for b_y in list((0,1)) :
            #looping on all 4 sub parts
            print (b_x*2-1), (b_y*2-1) ;
            udpate_to_pivot = np.asarray([ (b_x*2-1)*(pow(2,tot_level - level -2  )) 
                ,(b_y*2-1)*(pow(2,tot_level - level -2  ))
            ]); 
            sub_part_center_point = center_point +udpate_to_pivot; 
            
             
            
            # we want to iterateon 
            # we need to update : : point_array , index_array    center_point  , level
            #update point_array and index_array : we need to find the points that are in the subparts
            #update center point, we need to add/substract to previous pivot 2^level+11
            
            #find the points concerned :
            point_in_subpart_mask = np.logical_and(
                 testBit(point_array[:,0],level) ==b_x
                , testBit(point_array[:,1],level) ==b_y  ) ; 
            sub_part_points= point_array[point_in_subpart_mask]; 
            sub_part_index = index_array[point_in_subpart_mask];
            sub_part_center_point = center_point  + np.asarray([
                (b_x*2-1)*(pow(2,tot_level - level -2  ))
                ,(b_y*2-1)*(pow(2,tot_level - level -2  ))
                ]); 
                           
            
            if len(sub_part_points)>=1:
                recursive_octree_ordering(sub_part_points
                    ,sub_part_index
                    , sub_part_center_point
                    , sub_part_level
                    , tot_level
                    , result
                    , piv); 
                continue;
            else:
                print 'at televel ',level,'bx by:',b_x,' ',b_y,' refusing to go one, ', len(sub_part_points), ' points remaining fo this'
                continue;

rec = [] ;
piv = [] ; 
recursive_octree_ordering(pointcloud_int,index,pivot,0,3,rec, piv );
#recursive_octree_ordering(pointcloud_int,index, np.array([2,2]),1,3,rec, piv );
piv_ar = np.array(piv) 
plt.plot(piv_ar[:,0], piv_ar[:,1], 'ro') ;


plot(x=pointcloud_int[:,0].T,y=pointcloud_int[:,1].T, marker='o', color='r', ls='' )
plt.plot(pointcloud_int.T, marker='o', color='r', ls='')

plt.imsave('/')

from mpl_toolkits.mplot3d import Axes3D

plt.scatter(pointcloud[:,0], pointcloud[:,1],c='red');
plt.scatter(pointcloud_int[:,0], pointcloud_int[:,1],c='green');
plt.plot(pointcloud[:,0],pointcloud[:,1], 'ro')
plt.plot(pointcloud_int[:,0],pointcloud_int[:,1], 'ro')
plt.axis([-1, 8, -1, 8])
plt.show();

fig = plt.figure()
ax = fig.add_subplot(111)
ax.scatter(pointcloud_int[:,0], pointcloud_int[:,1]);
ax.scatter(pointcloud_int[:,0], pointcloud_int[:,1], pointcloud_int[:,0], zdir='z', c= 'red')
fig.show()


fig, axes = plt.subplots(1, 2, figsize=(12,3))
axes[0].scatter(pointcloud[:,0], pointcloud[:,1],c='red');
axes[1].scatter(pointcloud_int[:,0], pointcloud_int[:,1],c='green');
fig.show();

for f in list((0,1)):
    (f*2-1)