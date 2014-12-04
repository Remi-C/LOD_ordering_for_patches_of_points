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
 


  
    
#order_by_octree();
def test_order_by_octree_pg():
    iar =  [-101.085, 1288.533, 38.273, -101.326, 1289.471, 38.268, -100.592, 1289.422, 38.262, -101.291, 1289.424, 38.271, -100.904, 1288.646, 38.27, -101.497, 1289.061, 38.274, -101.296, 1288.568, 38.278, -101.432, 1288.508, 38.279, -100.72, 1288.811, 38.265, -101.173, 1289.031, 38.274, -101.109, 1289.236, 38.27, -100.606, 1289.32, 38.264, -101.159, 1289.383, 38.269, -100.92, 1288.898, 38.269, -101.43, 1289.266, 38.272, -100.651, 1289.217, 38.263, -101.331, 1288.617, 38.276, -100.745, 1288.709, 38.264, -101.359, 1289.02, 38.274, -100.821, 1288.904, 38.267, -100.631, 1289.318, 38.263, -101.041, 1289.441, 38.269, -100.536, 1288.924, 38.259, -100.633, 1288.564, 38.268, -101.25, 1288.572, 38.274, -101.344, 1289.32, 38.273, -100.605, 1289.471, 38.259, -101.069, 1289.039, 38.27, -101.072, 1288.736, 38.27, -101.363, 1289.27, 38.273, -100.508, 1289.076, 38.262, -100.586, 1289.371, 38.262, -101.187, 1289.332, 38.269, -101.105, 1289.387, 38.271, -100.588, 1288.971, 38.261, -100.882, 1288.9, 38.267, -101.044, 1288.738, 38.268, -101.331, 1289.271, 38.272, -100.643, 1289.467, 38.264, -100.63, 1289.068, 38.264, -101.237, 1288.623, 38.276, -101.443, 1289.164, 38.273, -101.079, 1289.488, 38.265, -100.735, 1288.859, 38.266, -101.191, 1289.23, 38.272, -101.463, 1289.463, 38.27, -100.864, 1288.648, 38.267, -100.906, 1288.596, 38.271, -100.822, 1289.207, 38.266, -100.793, 1289.107, 38.266, -100.536, 1288.824, 38.264, -100.535, 1289.074, 38.262, -100.73, 1288.76, 38.267, -101.303, 1288.922, 38.273, -101.34, 1289.121, 38.274, -101.37, 1289.119, 38.273, -100.568, 1288.771, 38.26, -100.837, 1288.854, 38.267, -101.04, 1288.688, 38.273, -101.058, 1289.24, 38.268, -100.617, 1289.42, 38.261, -100.711, 1289.414, 38.263, -100.733, 1288.91, 38.265, -100.982, 1289.195, 38.27, -100.749, 1288.859, 38.263, -101.134, 1289.385, 38.271, -101.381, 1288.664, 38.278, -100.982, 1289.445, 38.267, -101.226, 1289.078, 38.274, -101.269, 1288.621, 38.275, -101.316, 1289.422, 38.27, -101.057, 1289.34, 38.269, -101.263, 1289.176, 38.272, -100.695, 1289.164, 38.265, -100.897, 1289.301, 38.267, -100.686, 1289.414, 38.263, -101.258, 1288.926, 38.273, -100.736, 1289.162, 38.265, -101.372, 1288.967, 38.275, -101.269, 1288.52, 38.273, -101.382, 1288.613, 38.278, -101.325, 1289.121, 38.271, -100.624, 1288.564, 38.267, -100.528, 1289.475, 38.261, -100.621, 1289.068, 38.263, -101.497, 1289.16, 38.273, -100.501, 1289.277, 38.261, -101.151, 1289.133, 38.271, -100.757, 1289.311, 38.266, -100.52, 1289.227, 38.26, -100.676, 1288.914, 38.264, -100.516, 1288.824, 38.261, -100.743, 1288.91, 38.267, -100.76, 1289.311, 38.261, -101.015, 1288.639, 38.275, -101.082, 1289.438, 38.267, -101.392, 1289.418, 38.272, -100.635, 1289.119, 38.261, -101.424, 1289.115, 38.27, -100.718, 1289.113, 38.262]
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
    
    #plot_points(pointcloud, pointcloud_int,the_result, piv) ; 
    the_result= np.array(the_result);
    the_result[:,0]= the_result[:,0]+1 #ppython is 0 indexed, postgres is 1 indexed , we need to convert
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
    #print 'all the point ', point_array
    #print 'min_point ',min_point,'its index ', index_array[min_point],'the point ',  point_array[min_point] ; 
    
    #print 'n points before delete : ',len(point_array) ;     
    #removing the found point from the array of points 
    point_array= np.delete(point_array, min_point,axis=0 ) ;
    index_array= np.delete(index_array, min_point,axis=0 ) ;
    #print 'n points after delete : ',len(point_array) ; 
    #print 'all the point after delete ', point_array
    #print '\n\n';
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

test_order_by_octree_pg();