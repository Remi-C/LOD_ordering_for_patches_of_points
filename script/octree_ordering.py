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
def plot_points(point_cloud, points_scaled_quantized,result,piv):
    plt.clf()
    plt.cla()
    plt.close() 
    plt.close("all")
    piv_ar = [] ;
    r_ar = []; 
    piv_ar = np.array(piv)
    r_ar = np.array(result); 
    #print piv
    result_point = points_scaled_quantized[r_ar[:,0]] 

    
    fig1,ax1 = plt.subplots(nrows=1, ncols=1) ; 
    ax1.scatter(point_cloud[:,0], point_cloud[:,1],  c= 'red')
    #ax1.title('original_cloud')   
      
    fig, ( ax2,ax3,ax4) = plt.subplots(nrows=1, ncols=3,sharex=True,sharey=True);
     
   
    ax2.scatter(points_scaled_quantized[:,0], points_scaled_quantized[:,1], c='green');
    #ax2.title('scaled_quantized cloud');
    ax3.scatter(result_point[:,0], result_point[:,1],  c= 'blue')
    #ax3.title('chosen_points')    
    ax4.scatter(piv_ar[:,0], piv_ar[:,1], c='yellow');
    #ax4.title('mid octree points'); 
    fig1.show()
    fig.show()
    print result ;
 
#test_order_by_octree_pg();

  
    
#order_by_octree();
def test_order_by_octree_pg():
    iar = [-94.97, 1143.693, 38.933, -94.761, 1144.252, 38.57, -95.249, 1143.721, 38.583, -94.753, 1143.752, 38.579, -95.25, 1143.723, 39.165, -95.248, 1144.268, 38.572, -94.746, 1143.619, 39.14, -94.631, 1143.625, 38.576, -94.623, 1144.125, 38.569, -94.88, 1144.381, 38.57, -94.876, 1143.52, 39.338, -95.376, 1144.35, 38.572, -95.381, 1143.623, 39.306, -94.88, 1143.836, 38.577, -94.809, 1143.66, 39.132, -94.876, 1143.656, 39.15, -95.378, 1143.848, 38.58, -95.48, 1143.705, 38.591, -94.629, 1143.852, 38.573, -94.704, 1143.576, 39.146, -94.798, 1143.66, 39.035, -95.389, 1143.668, 39.235, -94.894, 1143.518, 39.076, -94.737, 1143.527, 38.801, -94.625, 1144.352, 38.567, -95.131, 1143.594, 39.331, -94.698, 1143.576, 39.046, -95.129, 1144.365, 38.572, -94.913, 1143.561, 38.669, -95.298, 1143.672, 38.594, -95.375, 1144.121, 38.576, -95.133, 1144.092, 38.575, -95.133, 1143.639, 39.26, -95.095, 1143.686, 38.772, -95.131, 1143.865, 38.577, -94.883, 1143.699, 39.027, -94.881, 1144.107, 38.573, -94.88, 1143.607, 38.585, -95.076, 1143.553, 39.358, -94.565, 1144.447, 38.523, -95.194, 1143.727, 39.154, -95.189, 1143.59, 39.341, -95.075, 1143.914, 38.575, -95.068, 1143.689, 39.193, -94.939, 1143.785, 38.58, -94.817, 1143.566, 38.583, -95.074, 1144.051, 38.574, -95.328, 1143.537, 39.386, -95.442, 1143.799, 38.583, -95.324, 1143.807, 38.58, -95.44, 1144.436, 38.571, -94.582, 1144.445, 38.552, -94.942, 1143.695, 38.947, -94.668, 1143.533, 39.019, -94.934, 1144.287, 38.571, -94.95, 1143.695, 39.138, -94.908, 1143.699, 39.131, -94.821, 1143.613, 38.864, -94.972, 1143.695, 39.145, -94.698, 1143.531, 39.153, -94.822, 1144.43, 38.567, -94.689, 1144.303, 38.568, -94.668, 1143.533, 39.134, -94.935, 1143.65, 38.585, -95.446, 1144.025, 38.577, -95.447, 1143.574, 39.359, -94.688, 1144.166, 38.57, -94.844, 1143.521, 39.317, -94.698, 1144.439, 38.565, -95.326, 1144.17, 38.573, -94.704, 1143.576, 39.139, -95.443, 1144.162, 38.576, -95.325, 1143.582, 39.354, -94.898, 1143.563, 39.101, -94.819, 1144.066, 38.572, -94.832, 1143.521, 39.219, -95.068, 1143.641, 38.585, -94.562, 1143.902, 38.568, -94.821, 1144.158, 38.573, -95.437, 1143.891, 38.577, -94.68, 1143.531, 39.145, -94.827, 1143.93, 38.575, -95.185, 1143.68, 38.584, -95.322, 1144.443, 38.57, -95.317, 1143.898, 38.577, -95.193, 1143.906, 38.576, -95.067, 1144.143, 38.573, -94.573, 1144.311, 38.553, -95.326, 1144.033, 38.577, -95.189, 1144.316, 38.571, -95.189, 1143.814, 38.579, -95.051, 1143.643, 38.685, -94.941, 1143.605, 39.276, -95.028, 1143.689, 38.836, -94.935, 1144.424, 38.569, -95.19, 1144.18, 38.574, -94.823, 1143.658, 39.137, -95.074, 1144.277, 38.573, -95.438, 1143.529, 39.389, -94.939, 1143.559, 38.588];    
    return order_by_octree_pg(iar,7,3,3);
    
    
def order_by_octree():
    #creating test data 
    tot_level,test_data_size,test_data_dim, pointcloud,index = \
        create_test_data(3,10,2); 
    
    #centering/scaling/quantizing the data
    pointcloud_int = center_scale_quantize(pointcloud,tot_level );  
     
    #initializing variablesoctree_ordering
    center_point,result,piv = preparing_tree_walking(tot_level) ;   
     
    #iterating trough octree : 
    recursive_octree_ordering(pointcloud_int,index,center_point, 0,tot_level,tot_level, result,piv) ;
    
    #print the result  
    plot_points(pointcloud, pointcloud_int,result, piv) ; 
    
    #test 
 
def order_by_octree_pg(iar,tot_level,stop_level,data_dim):  
    
    the_result = [];index =[];
    #converting the 1D array to 2D array
    temp_pointcloud = np.reshape(np.array(iar), (-1, data_dim))  ; 
    
    #we convert to 2D for ease of use 
    pointcloud = np.column_stack( (temp_pointcloud[:,0],temp_pointcloud[:,1]) )
 
    #creating the index array     
    index = np.arange(0,pointcloud.shape[0])   
    #centering/scaling/quantizing the data
    pointcloud_int = center_scale_quantize(pointcloud,tot_level );  
     
    #initializing variables
    center_point,the_result,piv = preparing_tree_walking(tot_level) ;   
     
    #iterating trough octree : 
    recursive_octree_ordering(pointcloud_int,index,center_point, 0,tot_level,stop_level, the_result,piv) ;
    
    return the_result ;
     


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
    new_max = np.amax(np.amax(pointcloud_int.T,axis=1)) #look for max range in X then Y then Z, then take the max of it
    if new_max !=0: #protection against pointcloud with only one points or line(2D) or flat(3D)
        max_r = new_max;
    
    #dividing so max scale is 0 . Now all the dimension are between [0,1]
    pointcloud_int = pointcloud_int/ max_r ; 
    
    #quantizing 
    smallest_int_size_possible = max(8*np.ceil(tot_level/8),8) #protection against 0 size
    if smallest_int_size_possible > 8 : 
        if smallest_int_size_possible > 32 :
            smallest_int_size_possible = max(32*np.ceil(tot_level/32),32) #protection against 0 size
        else :
            smallest_int_size_possible = max(16*np.ceil(tot_level/16),16) #protection against 0 size

    pointcloud_int =  np.trunc(abs((pointcloud_int* (1<<tot_level) )))\
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
     
     
     
def recursive_octree_ordering(point_array,index_array, center_point, level,tot_level,stop_level, result,piv):
    
    #updatig level;
    sub_part_level = level+1 ;
    #print for debug
    #recursive_octree_ordering_print(point_array,index_array, center_point, level,tot_level, result,piv);
        
    if ( (len(point_array) == 0) | level >=min(tot_level,stop_level)):
        return;
     
    #print 'level ',level,' , points remaining : ',len(point_array) ;
    #print center_point;
    piv.append(center_point); 
    
    
    #find the close    st point to pivot 
    min_point = np.argmin(np.sum(np.abs(point_array - center_point ),axis=1))
    result.append(list((index_array[min_point],level))) ;  
    print 'all the point ', point_array
    print 'min_point ',min_point,'its index ', index_array[min_point],'the point ',  point_array[min_point] ; 
    
    print 'n points before delete : ',len(point_array) ;     
    #removing the found point from the array of points 
    point_array= np.delete(point_array, min_point,axis=0 ) ;
    index_array= np.delete(index_array, min_point,axis=0 ) ;
    print 'n points after delete : ',len(point_array) ; 
    print 'all the point after delete ', point_array
    print '\n\n';
    #stopping if it remains no pioint : we won't divide further, same if we have reached max depth
    if (len(point_array) ==0 )|(level >= min(tot_level,stop_level)):
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
                    , stop_level
                    , result
                    , piv); 
                continue;
            else:
                print 'at televel ',level,'bx by:',b_x,' ',b_y,' refusing to go one, ', len(sub_part_points), ' points remaining fo this'
                continue;

 