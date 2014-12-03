# -*- coding: utf-8 -*-
"""
MidOc ordering of point cloud

input is 3*n float list represeneting 3D poitns
we order the point by the MidOc ordering

@author: remi
"""

#importing modules
import numpy as np; 
import matplotlib.pyplot as plt
#from numpy import random ;
#
#def plot_points(point_cloud, points_scaled_quantized,result,piv):
#    plt.clf()
#    plt.cla()
#    plt.close() 
#    piv_ar = [] ;
#    r_ar = []; 
#    piv_ar = np.array(piv)
#    r_ar = np.array(result); 
#    #print piv
#    result_point = points_scaled_quantized[r_ar[:,0]] 
#
#    
#    fig1,ax1 = plt.subplots(nrows=1, ncols=1) ; 
#    ax1.scatter(point_cloud[:,0], point_cloud[:,1],  c= 'red')
#    #ax1.title('original_cloud')   
#      
#    fig, ( ax2,ax3,ax4) = plt.subplots(nrows=1, ncols=3,sharex=True,sharey=True);
#     
#   
#    ax2.scatter(points_scaled_quantized[:,0], points_scaled_quantized[:,1], c='green');
#    #ax2.title('scaled_quantized cloud');
#    ax3.scatter(result_point[:,0], result_point[:,1],  c= 'blue')
#    #ax3.title('chosen_points')    
#    ax4.scatter(piv_ar[:,0], piv_ar[:,1], c='yellow');
#    #ax4.title('mid octree points'); 
#    fig1.show()
#    fig.show()


def order_by_octree():
    #creating test data 
    tot_level,test_data_size,test_data_dim, pointcloud,index = \
        create_test_data(5,10000,2); 
    
    #centering/scaling/quantizing the data
    pointcloud_int = center_scale_quantize(pointcloud,tot_level );  
     
    #initializing variablesoctree_ordering
    center_point,result,piv = preparing_tree_walking(tot_level) ;   
     
    #iterating trough octree : 
    recursive_octree_ordering(pointcloud_int,index,center_point, 0,tot_level, result,piv) ;
    
    #print the result  
    plot_points(pointcloud, pointcloud_int,result, piv) ; 
    
    #test 
 
def order_by_octree_pg(iar,tot_level,data_dim):
    the_result = [];
    #converting the 1D array to 2D array
    np_array = np.reshape(np.array(iar), (-1, 3))  ; 
    
    #centering/scaling/quantizing the data
    pointcloud_int = center_scale_quantize(pointcloud,tot_level );  
     
    #initializing variables
    center_point,the_result,piv = preparing_tree_walking(tot_level) ;   
     
    #iterating trough octree : 
    recursive_octree_ordering(pointcloud_int,index,center_point, 0,tot_level, the_result,piv) ;
    
    #return the_result ;
    

def create_test_data(tot_level,test_data_size,test_data_dim): 
    """Simple helper function to create a pointcloud with random values"""
    return tot_level,test_data_size,test_data_dim \
        ,np.random.rand(test_data_size,test_data_dim)\
        ,np.arange(0,test_data_size) ;
        
        
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
                
def array_to_bit(array):
    funcs = [lambda x: np.binary_repr(x)]
    apply_vectorized = np.vectorize(lambda f, x: f(x))
    return apply_vectorized(funcs, array);
 

def preparing_tree_walking(tot_level): 
    """ preparing input/output of ordering, computing center_point, puttig result and iv to [];"""
    #preparing input/output of ordering
    #computing center_point, 
    center_point = np.array([pow(2,tot_level-1),pow(2,tot_level-1)])
    #puttig result and iv to [];
    return center_point,[],[];
    

def recursive_octree_ordering_print(point_array,index_array, center_point, level,tot_level, result,piv):
    #importing necessary lib
    import numpy as np;
    print '\n\n working on level : '+str(level); 
    print 'input points: \n\t',point_array ; 
    print 'index_array : \n\t',index_array;
    print 'center_point : \n\t',center_point;
    print 'level : \n\t',level;
    print 'tot_level : \n\t',tot_level;
    print 'result : \n\t',result;
    #stopping condition : no points:
     
     
     
def recursive_octree_ordering(point_array,index_array, center_point, level,tot_level, result,piv):
    
    #updatig level;
    sub_part_level = level+1 ;
    #print for debug
    #recursive_octree_ordering_print(point_array,index_array, center_point, level,tot_level, result,piv);
        
    if ( (len(point_array) == 0) | (level>=tot_level)):
        return;
     
    #print 'level ',level,' , points remaining : ',len(point_array) ;
    #print center_point;
    piv.append(center_point); 
    
    
    #find the close    st point to pivot 
    min_point = np.argmin(np.sum(np.abs(point_array - center_point ),axis=1))
    result.append(list((index_array[min_point],level))) ;  
    
    #removing the found point from the array of points 
    np.delete(point_array, min_point, axis=None) ;
    np.delete(index_array, min_point, axis=None) ;
    
    #stopping if it remains no pioint : we won't divide further, same if we have reached max depth
    if (len(point_array) ==0 )|(level >= tot_level):
        return;

    #compute the 4 sub parts
    for b_x in list((0,1))  :
        for b_y in list((0,1)) :
            #looping on all 4 sub parts
            #print (b_x*2-1), (b_y*2-1) ;
            udpate_to_pivot = np.asarray([ (b_x*2-1)*(pow(2,tot_level - level -2  )) 
                ,(b_y*2-1)*(pow(2,tot_level - level -2  ))
            ]); 
            sub_part_center_point = center_point +udpate_to_pivot; 
            
             
            
            # we want to iterateon 
            # we need to update : : point_array , index_array    center_point  , level
            #update point_array and index_array : we need to find the points that are in the subparts
            #update center point, we need to add/substract to previous pivot 2^level+11
            
            #find the points concerned :
            
            point_in_subpart_mask =( (
                 testBit(point_array[:,0],tot_level - level -1 ) ==b_x)
                == ( testBit(point_array[:,1],tot_level - level -1 ) ==b_y  ) ); 
            
            #point_in_subpart_mask = np.all(    testBit(point_array,tot_level-level-1)== np.array([b_x,b_y]), axis=1)       
            #point_in_subpart_mask = np.all(testBit_arr(point_array, [b_x,b_y]),axis=1) ; 
            #point_in_subpart_mask = np.logical_and(
            #     testBit(point_array[:,0],level) ==b_x
            #    , testBit(point_array[:,1],level) ==b_y  ) ; 
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

 