import math

def create_clusters(n, k, method, data):
    clusters = convert_points_to_1_item_clusters(data)
    
    while len(clusters) > k:
        i, j = find_closest_clusters(clusters, method)
        new_cluster = clusters[i] + clusters[j]
        if i > j:
            del clusters[i]
            del clusters[j]
        else:
            del clusters[j]
            del clusters[i]
        clusters.append(new_cluster)
        
    return clusters

def convert_points_to_1_item_clusters(data):
    clusters = []
    for point in data:
        clusters.append([point])
        
    return clusters

def find_closest_clusters(clusters, method):
    if method == 0:
        return single_link(clusters)
    elif method == 1:
        return complete_link(clusters)
    else:
        return average_link(clusters)

def single_link(clusters):
    inter_cluster_min_dist = float('inf')
    cluster_idxs = ()
    for i in range(len(clusters)):
        for j in range(i+1, len(clusters)):
            single_link_dist = float('inf')
            for _, x1, y1 in clusters[i]:
                for _, x2, y2 in clusters[j]:
                    distance = math.sqrt((y2-y1)**2 + (x2-x1)**2)
                    if distance < single_link_dist:
                        single_link_dist = distance
            
            if single_link_dist < inter_cluster_min_dist:
                inter_cluster_min_dist = single_link_dist
                cluster_idxs = (i, j)
    
    return cluster_idxs

def complete_link(clusters):
    inter_cluster_min_dist = float('inf')
    cluster_idxs = ()
    for i in range(len(clusters)):
        for j in range(i+1, len(clusters)):
            complete_link_dist = -1
            for _, x1, y1 in clusters[i]:
                for _, x2, y2 in clusters[j]:
                    distance = math.sqrt((y2-y1)**2 + (x2-x1)**2)
                    if distance > complete_link_dist:
                        complete_link_dist = distance
            
            if complete_link_dist < inter_cluster_min_dist:
                inter_cluster_min_dist = complete_link_dist
                cluster_idxs = (i, j)
    
    return cluster_idxs

def average_link(clusters):
    inter_cluster_min_dist = float('inf')
    cluster_idxs = ()
    for i in range(len(clusters)):
        for j in range(i+1, len(clusters)):
            avg_link_dist = float('inf')
            sum_dist = 0
            for _, x1, y1 in clusters[i]:
                for _, x2, y2 in clusters[j]:
                    sum_dist = sum_dist + math.sqrt((y2-y1)**2 + (x2-x1)**2)
            
            avg_link_dist = sum_dist/(len(clusters[i]) * len(clusters[j]))
            
            if avg_link_dist < inter_cluster_min_dist:
                inter_cluster_min_dist = avg_link_dist
                cluster_idxs = (i, j)
    
    return cluster_idxs

first_line = input().split(" ")
N = int(first_line[0])
K = int(first_line[1])
M = int(first_line[2])

points = []
for i in range(N):
    p = input().split(" ")
    points.append((i, float(p[0]), float(p[1])))

clustered_data = create_clusters(N, K, M, points)

ordered_clusters = {}
cluster_id = 0
for cluster in clustered_data:
    for row, p1, p2 in cluster:
        ordered_clusters[row] = cluster_id
    cluster_id = cluster_id + 1

for i in range(len(ordered_clusters.keys())):
    print(ordered_clusters[i])