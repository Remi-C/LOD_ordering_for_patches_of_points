# -*- coding: utf-8 -*-
"""
Created on Sun Jan  4 15:13:53 2015

@author: remi
"""



import psycopg2

def connect_to_base():
    conn = psycopg2.connect(  
        database='test_pointcloud'
        ,user='postgres'
        ,password='postgres'
        ,host='localhost'
        ,port='5433' ) ; 
    cur = conn.cursor()
    return conn, cur ;
    
def set_search_path(conn,cur):
    #setting the search path    
    cur.execute("""SET search_path to lod,benchmark_cassette_2013, public; """); 
    conn.commit(); 


def execute_querry(q,arg_list,conn,cur): 
    
    #print q % arg_list ;  
    cur.execute( q ,arg_list)
    conn.commit()
    
def order_patch_by_octree(conn,cur,ipatch, tot_level,stop_level,data_dim):
    import numpy as np; 
    import psycopg2 ;
    import datetime;  
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
    
def test_order_by_octree():
    import psycopg2 ;
    import datetime;
    import octree_ordering;
    tot_level = 6;
    stop_level = 4 ;
    data_dim = 3 ; 
    time_beginning = datetime.datetime.now() ; 
    print 'starting : %s ' % (datetime.datetime.now()); 
    conn,cur = connect_to_base();
    set_search_path(conn,cur);
    
    q = """DROP TABLE IF EXISTS test_order_out_of_db ; 
    CREATE TABLE test_order_out_of_db(
        gid int,
        patch pcpatch(6),
        points_per_level int[]
    ) ; 
    """ ; 
    execute_querry(q,[],conn,cur) ;
    
    for i in range(1, 1000):
        if i %10 == 0:
            print '\t starting loop %s : %s ' % (i,datetime.datetime.now()); 
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
        INSERT INTO test_order_out_of_db VALUES (%s,%s,%s);
        """
        arg_list = [gid,opatch,ppl] ; 
        execute_querry(q,arg_list,conn,cur) ;
        
    
    #print result   
    
    cur.close()
    conn.close() 
    print 'ending : %s ' % (datetime.datetime.now()); 
    
    time_end = datetime.datetime.now()
    
    print 'duration : %'% (time_end-time_beginning)
    
test_order_by_octree()

02:34:35.491445 
02:36:50.137871
2min15 : 1031797
100Million ps/hr
1031797 / (2*60+15)

7642*3600
