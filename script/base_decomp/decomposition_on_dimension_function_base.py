# -*- coding: utf-8 -*-
"""
Created on Wed Dec 10 10:15:17 2014

@author: remi
"""

import numpy as np;

  
def compute_base_matrix(n_level,start_level):
    """compute matrix for base of function f_k(i)=(2**k)**i"""
    B = np.zeros([n_level,n_level],dtype=int);
    for k in np.arange(0,n_level):
        for i in np.arange(0,n_level):
                B[k,i] = pow(pow(2,k+1+start_level),i+1) ;
    print B;
    return np.linalg.inv(B) ; 
 
def pg_to_np(gid, points_per_level):
    gid_arr  = np.array(gid,dtype=int);
    ppl_arr =  np.reshape(np.array(points_per_level), (-1, len(points_per_level)/len(gid_arr)) ) ; 
    return gid_arr, ppl_arr; 

def apply_inv_mat(arr, B_inv): 
    return B_inv.dot(arr)

def compute_decomposition(ppl_arr,B_inv):
    return np.apply_along_axis(apply_inv_mat, 1, ppl_arr, B_inv ) 

def decompose_pg(gid, points_per_level,start_level,n_level):
    #converting input
    gid_arr, ppl_arr = pg_to_np(gid, points_per_level);
    
    #computing matrix
    B_inv = compute_base_matrix(n_level,start_level) ;  
    
    decomp_vect = compute_decomposition(ppl_arr,B_inv);  
    decomp_vect /= np.sqrt((decomp_vect ** 2).sum(-1))[..., np.newaxis]
    return np.around(np.abs(decomp_vect),3)
    

def decompose_pg_test(n_level):
    #emulating input
    gid =  [918,919,920,921,922];
    points_per_level = [4, 16, 64, 4, 16, 64, 4, 16, 64, 6, 20, 71, 4, 16, 64]; 
    start_level= 0;
    
    return decompose_pg(gid, points_per_level,start_level,n_level)
    

print decompose_pg_test(3)


    