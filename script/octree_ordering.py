# -*- coding: utf-8 -*-
"""
MidOc ordering of point cloud

input is 3*n float list represeneting 3D poitns
we order the point by the MidOc ordering

@author: remi
"""

#importing modules
import numpy as np; 
#from numpy import random ;

#creating test data 
tot_level,test_data_size,test_data_dim, pointcloud,index = \
    create_test_data(3,200,2); 

#centering/scaling/quantizing the data
pointcloud_int = center_scale_quantize(pointcloud,tot_level );  

def recursive_octree_ordering(point_array,index_array, center_point, level,tot_level, result,piv):


    
    
testBit_arr(pointcloud_int,  np.asarray([(0,1)]) )
toto= np.column_stack((testBit(pointcloud_int[:,0],0), testBit(pointcloud_int[:,1],1)) )

toto == testBit_arr(pointcloud_int,  np.asarray([(0,1)]) )
 















def create_test_data(tot_level,test_data_size,test_data_dim): 
    """Simple helper function to create a pointcloud with random values"""
    return tot_level,test_data_size,test_data_dim \
        ,np.random.rand(test_data_size,test_data_dim),np.arange(1,test_data_size+1) ;
        
        
def center_scale_quantize(pointcloud,tot_level ):
    """ Centers/scale the data so that everything is between 0 and 1
        Don't deformate axis between theim. 
        Quantize using the number of level 
        @param a 2D numpy array, column = X,Y(,Z)  
        @param the number of bit we want to quantize on  
        @return a ne point cloud, same number of points, but everything between 0 and 1, and quantized
        """   
    data_dim = pointcloud.shape[1] ; 
    #centering data so that all dim start at 0 
    pointcloud_int = pointcloud - np.amin(pointcloud.T, axis=1); 
    
    #finding the max scaling, that is the biggest range in dimension X or Y or Z
    max_r = 1 ;
    new_max = np.amax(np.amax(pointcloud.T,axis=1)) #look for max range in X then Y then Z, then take the max of it
    if new_max !=0: #protection against pointcloud with only one points or line(2D) or flat(3D)
        max_r = new_max;
    
    #dividing so max scale is 0 . Now all the dimension are between [0,1]
    pointcloud_int = pointcloud/ max_r ; 
    
    #quantizing 
    smallest_int_size_possible = max(8*np.ceil(tot_level/8),8) #protection against 0 size
    if smallest_int_size_possible > 8 : 
        if smallest_int_size_possible > 32 :
            smallest_int_size_possible = max(32*np.ceil(tot_level/32),32) #protection against 0 size
        else :
            smallest_int_size_possible = max(16*np.ceil(tot_level/16),16) #protection against 0 size

    pointcloud_int =  np.trunc(abs((pointcloud* (1<<tot_level) )))\
         .astype(np.dtype('uint'+str(int(smallest_int_size_possible))));
    #we have to take care of overflow : if we reach the max value of 1<<tot_level, we go one down
    pointcloud_int[pointcloud_int==(1<<tot_level)]=((1<<tot_level)-1); 
    
    return pointcloud_int


def testBit(int_type, offset):
    mask = 1 << offset
    return( (int_type & mask)>0 )
    
def testBit_arr(int_type, offset):
    mask = offset*0 +1;
    mask = mask << offset
    return( ( np.bitwise_and(int_type,mask)>0 ) )
    
    
def preparing_tree_walking(): 
    """ preparing input/output of ordering, computing center_point, puttig result and iv to [];"""
    #preparing input/output of ordering
    #computing center_point, 
    
    #puttig result and iv to [];
    return ,[],[];