# -*- coding: utf-8 -*-
"""
Created on Sun Jan  4 15:13:53 2015

@author: remi
"""



import psycopg2

def connect_to_base():
    conn = psycopg2.connect(  
        database='vosges'
        ,user='postgres'
        ,password='postgres'
        ,host='172.16.3.50'
        ,port='5432' ) ; 
    cur = conn.cursor()
    return conn, cur ; 

def execute_querry(q,arg_list,conn,cur): 
    
    #print q % arg_list ;  
    cur.execute( q ,arg_list)
    conn.commit()
    
def order_patch_by_octree(conn,cur,ipatch, tot_level,stop_level,data_dim):
    import numpy as np;  
    import octree_ordering;
    round_size = 3 
    #get points  :
    q =  """SELECT 
			round(PC_Get((pt).point,'X'),%s)::float  as x
			, round(PC_Get((pt).point,'Y'),%s)::float as y 
			, round(PC_Get((pt).point,'Z'),%s)::float as  z
			--,((pt).ordinality)::int
		FROM  rc_explodeN_numbered(%s,-1) as pt;
    
    """ ;
    arg_list = [round_size,round_size,round_size,ipatch] ; 
    execute_querry(q,arg_list,conn,cur) ;
    pointcloud = np.asarray(cur.fetchall())
    #print pointcloud ;  
    
    the_result = [];index =[];
    point_cloud_length = pointcloud.shape[0] ; 
    index = np.arange(1,point_cloud_length+1) 
    pointcloud_int = octree_ordering.center_scale_quantize(pointcloud,tot_level );
    pointcloud=[];
    center_point,the_result,piv = octree_ordering.preparing_tree_walking(tot_level) ; 
    points_to_keep = np.arange(point_cloud_length,dtype=int);
    octree_ordering.recursive_octree_ordering_ptk(points_to_keep, pointcloud_int,index,center_point, 0,tot_level,stop_level, the_result,piv) ;
    #the_result= np.array(the_result);
    #the_result[:,0]= the_result[:,0]+1 #ppython is 0 indexed, postgres is 1 indexed , we need to convert
     
    #return np.asarray(the_result) + 1;
    q = """
    WITH  points AS (
		SELECT 
			(pt).ordinality
			, pt.point as opoint
		FROM  rc_explodeN_numbered( %s,-1) as pt   
		) 
	, points_LOD as (
		SELECT unnest(%s) as ordering , unnest(%s) as level
          
	)
	, pt_p_l AS (
		SELECT array_agg(n_per_lev::int oRDER BY level ASC ) as points_per_level
		FROM 
			(SELECT  level, count(*) as n_per_lev
			FROM points_LOD
			GROUP BY level ) as sub
	)
	SELECT    pa.patch , pt_p_l.points_per_level 
	FROM  pt_p_l, 
		(  
		SELECT  pc_patch(points.opoint order by level ASC NULLS LAST, random())  as patch
		FROM points
			LEFT OUTER JOIN points_LOD  AS plod on (points.ordinality = plod.ordering) 
		) as pa ;"""
    
    #print the_result
    arg_list = [ipatch, np.asarray(the_result)[:,0].tolist(), np.asarray(the_result)[:,1].tolist()  ] ; 
    execute_querry(q,arg_list,conn,cur) ;
    return cur.fetchall()[0] ; 

def simple_order(gid, tot_level,stop_level,data_dim,conn,cur):

    import psycopg2 ; 
    import octree_ordering;   
    q = """
        SELECT gid, patch
        FROM vosges_2011.las_vosges  
        WHERE gid = %s
        """;
    arg_list = [gid] ; 
    execute_querry(q,arg_list,conn,cur) ;
    gid , patch =  cur.fetchall()[0] ;
    opatch,ppl = order_patch_by_octree(conn,cur, patch, tot_level,stop_level,data_dim)
    q = """
        UPDATE vosges_2011.las_vosges SET (patch, points_per_level) = (%s,%s)
        WHERE gid = %s;
        """
    arg_list = [opatch,ppl,gid] ; 
    execute_querry(q,arg_list,conn,cur) ;
    return gid ;
        
def test_order_by_octree():
    import psycopg2 ;
    import datetime;
    import octree_ordering; 
    
    
    print 'starting : %s ' % (datetime.datetime.now()); 
    conn,cur = connect_to_base();
    set_search_path(conn,cur);
    
    q = """DROP TABLE IF EXISTS public.test_order_out_of_db ; 
    CREATE TABLE public.test_order_out_of_db(
        gid int,
        patch pcpatch(6),
        points_per_level int[]
    ) ; 
    """ ; 
    execute_querry(q,[],conn,cur) ;
    
    for i in range(1, 1000):
        if i %10 == 0:
            print '\t\t starting loop %s : %s ' % (i,datetime.datetime.now()); 
        q = """
        SELECT gid, patch
        FROM benchmark_cassette_2013.riegl_pcpatch_space  
        WHERE gid = %s
        """;
        arg_list = [i] ; 
        execute_querry(q,arg_list,conn,cur) ;
        gid , patch =  cur.fetchall()[0] ;
        #print gid, patch
        opatch,ppl = order_patch_by_octree(conn,cur, patch, tot_level,stop_level,data_dim)
                
        q = """
        INSERT INTO public.test_order_out_of_db VALUES (%s,%s,%s);
        """
        arg_list = [gid,opatch,ppl] ; 
        execute_querry(q,arg_list,conn,cur) ;
        
    
    #print result   conn,cur = connect_to_base();
    set_search_path(conn,cur);
    
    q = """DROP TABLE IF EXISTS public.test_order_out_of_db ; 
    CREATE TABLE public.test_order_out_of_db(
        gid int,
        patch pcpatch(6),
        points_per_level int[]
    ) ; 
    """ ; 
    execute_querry(q,[],conn,cur) ;
    
    cur.close()
    conn.close() 
    print '\t ending : %s ' % (datetime.datetime.now()); 
     
#test_order_by_octree()
  
    
    


def batch_LOD_multiprocess(processes,split_number,key_tot_start,key_tot_end,the_step): 
    """Main function, execute a given query in parallel on server"""
    import  multiprocessing as mp; 
    import random;
    #splitting the start_end into split_number interval
    subintervals = split_interval_into_smaller_interval(split_number,key_tot_start,key_tot_end,the_step);
    #shuffle so that subintervals are in random order
    random.shuffle(subintervals); 
    
    #batch_LOD_monoprocess([1,100,1]);
    #return 
    #multiprocessing: 
    pool = mp.Pool(processes); 
    results = pool.map(batch_LOD_monoprocess, subintervals)
    return results
    
def split_interval_into_smaller_interval(split_number,key_tot_start,key_tot_end, the_step):
    """ simply takes a big interval and split it into small pieces. Warning, possible overlaps of 1 elements at the beginning/end"""
    import numpy as np    
    import math
    key_range = abs(key_tot_end-key_tot_start)/(split_number *1.0) 
    interval_to_process = [] ;
    for i,(proc) in enumerate(np.arange(1,split_number+1)):
        key_local_start = int(math.ceil(key_tot_start+i * key_range)) ;
        key_local_end = int(math.trunc(key_tot_start+(i+1) * key_range)); 
        interval_to_process.append([ key_local_start , key_local_end, the_step])        
        #batch_LOD_monoprocess(key_min,key_max,key_step):
    #print interval_to_process
    return interval_to_process 
   

def batch_LOD_monoprocess((key_min,key_max,key_step)): 
    """ this function connect to databse, and execute the querry on the specified gid range, step by step"""    
    import multiprocessing; 
    tot_level = 8;
    stop_level = 6 ;
    data_dim = 3 ; 
    #connect to db
    conn,cur = connect_to_base(); 

    #setting the search path    
    cur.execute("""SET search_path to vosges , public;"""); 
    conn.commit(); 
    
    
    i = key_min; 
    while i <= key_max :
        simple_order(i, tot_level,stop_level,data_dim,conn,cur) ;
        i+=key_step ; 
        #if i %int(key_max/10.0-key_min/10.0) == 0 : 
        #    adv = round((1.0*i-key_min)/(key_max*1.0-key_min*1.0),2);
        #    print '\t %s: %s %s ' % (str(multiprocessing.current_process().name),' '*int(10*adv),str(adv))
    print '\t %s' % str(multiprocessing.current_process().name) ; 
    cur.close()
    conn.close()
    
def batch_LOD_multiprocess_test():
    """ test of the main function, parameters adapted to IGN big server""" 
    import datetime ; 
    time_start = datetime.datetime.now(); 
    print 'starting : %s ' % (time_start); 
    
    key_tot_start=8736
    key_tot_end= 590264 #6554548
    key_step = 1 ;
    processes = 15 ;
    split_number = processes*100; 
    # creating a table to hold results    

      
    batch_LOD_multiprocess(processes,split_number,key_tot_start,key_tot_end,key_step); 
    time_end = datetime.datetime.now(); 
    print 'ending : %s ' % (time_end); 
    print 'duration : %s ' % (time_end-time_start)
    
#batch_LOD_multiprocess_test();