# -*- coding: utf-8 -*-
"""
Created on Tue Jan  6 09:50:48 2015

@author: remi
"""

#############
import numpy as np ;
import networkx as nx;
from matplotlib import cm as cmap

labels =  ['unclassified', 'ground', 'building', 'other object', 'static', 'Dynamic', 'natural']; #noms humain des classes
cm = np.array(
[[ 0.14423077,0.04807692,0.08653846,0.23076923,0.14423077,0.20192308,0.14423077],
 [ 0.03495234,0.66908761,0.09078529,0.03177485,0.04539265,0.07852928,0.04947798],
 [ 0.08854021,0.13589241,0.20005604,0.15830765,0.14569908,0.1745587,0.09694592],
 [ 0.18627451,0.01960784,0.00980392,0.38235294,0.06862745,0.02941176,0.30392157],
 [ 0.06321839,0.,0.08045977,0.12068966,0.5862069,0.10344828,0.04597701],
 [ 0.11591696,0.08477509,0.1384083,0.1349481,0.09515571,0.35986159,0.07093426],
 [ 0.08496267,0.00959829,0.0373267,0.17525773,0.03412727,0.03661571,0.62211162]]
) ; #matrice de confusion normalisée
G = nx.from_numpy_matrix(cm) #on crée un graphe, avec les edges qui ont les poids correspondant à des confusion
G = nx.relabel_nodes(G,mapping=dict(zip(G.nodes(),labels))) # on met les noms humains dans le graphe, c'est plus facile à comprendre



edgewidth = [ d['weight']*100 for (u,v,d) in G.edges(data=True)] #on récupere les poids de chaque edge, pour le coloriage 
nx.draw_spectral(G,node_color='g',edge_color = [ i[2]['weight'] for i in G.edges(data=True) ], edge_cmap=cmap.get_cmap('jet')
, width=edgewidth  ,font_size=10,font_weight='bold',font_family='' ) # ça clusterizespectralement le graphe (ie la matrice cm), puis place les noeuds selon des distances dans l'espace de clustering. Le reste fait du pretty print
print(G)#afficher

##calculer les positions des noeuds :
pos = nx.spectral_layout(G, dim=2, weight='weight', scale=1) ;
pos_xyz = np.zeros([len(labels),2],dtype = float);  
for j in  range(0, len(labels) ):
    pos_xyz[j] = np.asarray(pos[labels[j]])

#maintenant on a un tableau de points 3D qui représentent chacun une classe.
#on peut utiliser l'algo de clustering que l'on préfère.
#en voici 2
from sklearn.cluster import MeanShift, estimate_bandwidth
bandwidth = estimate_bandwidth(pos_xyz, quantile=0.5, n_samples=5000)
ms = MeanShift(bandwidth=bandwidth, bin_seeding=True)
ms.fit(pos_xyz)
cluster_number = ms.labels_

from sklearn.cluster import AffinityPropagation
af = AffinityPropagation(damping=0.9,max_iter=10000,convergence_iter=150,affinity='euclidean').fit(pos_xyz )
 
cluster_number = af.labels_
cluster_centers_indices = af.cluster_centers_indices_
n_clusters_ = len(cluster_centers_indices)
cluster_number = af.labels_

#maintenant on a pour chaque classe la position , et le numero du cluster associé
#on va calculer les formes géoémtriques patatoides pour chaque cluster
import shapely
from shapely.geometry import MultiPoint
from shapely.geometry import asMultiPoint

mps = [] ;#list de multipoints, séparé par cluster
for i in range(0,n_clusters_):
    mps.append(asMultiPoint(pos_xyz[cluster_number==i]))

bb_mps = []    #liste de multipoints double bufferisé (morpho math !)
for i in range(0,n_clusters_):
    bb_mps.append(
    mps[i].buffer(1.0).buffer(-0.95)   
    )

###plot madness !
#tracer les patatoides
from matplotlib.patches import Polygon 
from matplotlib import colors;
polygons = bb_mps; 
a_colour_map = cmap.get_cmap('jet')
jet = cmap.get_cmap('jet') 
cNorm  = colors.Normalize(vmin=0, vmax= 1 )
scalarMap = cmap.ScalarMappable(norm=cNorm, cmap=jet) 

colorVal = scalarMap.to_rgba(0.2)
fig, ax = plt.subplots(figsize=(8, 8))
for i,(polygon) in enumerate(polygons):
    mpl_poly = Polygon(np.array(polygon.exterior) , color = scalarMap.to_rgba(i*1.0/len(polygons)),   lw=0, alpha=0.8)
    ax.add_patch(mpl_poly)
ax.relim()
ax.autoscale()
#ajouter le graphe et les noeuds
labels_pos = []
for i in range(0, len(labels)):
    labels_pos.append([labels[i],i])
dict_l_p = dict(labels_pos)  

nx.draw_spectral(G,node_color=[ cluster_number[dict_l_p[i[0]]] for i in G.nodes(data=True) ],edge_color = [ i[2]['weight'] for i in G.edges(data=True) ], edge_cmap=cmap.get_cmap('jet') 
, width=edgewidth  ,font_size=10,font_weight='bold',font_family='' ) 

 
############
