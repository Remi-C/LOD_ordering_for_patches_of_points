##!/usr/bin/env python

def hist2d_bubble(x_data, y_data, bins=10):
    import numpy as np
    import matplotlib.pyplot as pyplot
    ax = np.histogram2d(x_data, y_data, bins=bins)
    xs = ax[1]
    dx = xs[1] - xs[0]
    ys = ax[2]
    dy = ys[1] - ys[0]
    def rdn():
        return (1-(-1))*np.random.random() + -1
    points = []
    for (i, j),v in np.ndenumerate(ax[0]):
        points.append((xs[i], ys[j], v))

    points = np.array(points)
    fig = pyplot.figure()
    sub = pyplot.scatter(points[:, 0],points[:, 1],
                         color='black', marker='o', s=128*points[:, 2])
    sub.axes.set_xticks(xs)
    sub.axes.set_yticks(ys)
    pyplot.ion()
    pyplot.grid()
    pyplot.show()
    return points, sub

def hist3d_bubble(x_data, y_data, z_data, bins=10):
    import numpy as np
    import matplotlib.pyplot as pyplot
    from mpl_toolkits.mplot3d import Axes3D
    ax1 = np.histogram2d(x_data, y_data, bins=bins)
    ax2 = np.histogram2d(x_data, z_data, bins=bins)
    ax3 = np.histogram2d(z_data, y_data, bins=bins)
    xs, ys, zs = ax1[1], ax1[2], ax3[1]
    dx, dy, dz = xs[1]-xs[0],  ys[1]-ys[0], zs[1]-zs[0]
    def rdn():
        return (1-(-1))*np.random.random() + -1
    smart = np.zeros((bins, bins, bins),dtype=int)
    for (i1, j1), v1 in np.ndenumerate(ax1[0]):
        if v1==0: continue
        for k2, v2 in enumerate(ax2[0][i1]):
            v3 = ax3[0][k2][j1]
            if v1==0 or v2==0 or v3==0: continue
            num = min(v1, v2, v3)
            smart[i1, j1, k2] += num
            v1 -= num
            v2 -= num
            v3 -= num
    points = []
    for (i,j,k),v in np.ndenumerate(smart):
        points.append((xs[i], ys[j], zs[k], v))
    points = np.array(points)
    fig = pyplot.figure()
    sub = fig.add_subplot(111, projection='3d')
    sub.scatter(points[:, 0], points[:, 1], points[:, 2],
                color='black', marker='o', s=128*points[:, 3])
    sub.axes.set_xticks(xs)
    sub.axes.set_yticks(ys)
    sub.axes.set_zticks(zs)
    pyplot.ion()
    pyplot.grid()
    pyplot.show()
    return points, sub
 

temperature = [4,   3,   1,   4,   6,   7,   8,   3,   1]
radius      = [0,   2,   3,   4,   0,   1,   2,  10,   7]
density     = [1,  10,   2,  24,   7,  10,  21, 102, 203]
import matplotlib
matplotlib.rcParams.update({'font.size':14})

points, sub = hist2d_bubble(radius, density, bins=4)
sub.axes.set_xlabel('radius')
sub.axes.set_ylabel('density')
