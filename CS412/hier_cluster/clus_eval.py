import math

total_points_count = 0
count_per_cluster = {}
count_per_truth = {}
count_per_truth_given_cluster = {}
tp = 0
fn = 0
fp = 0

data = []
while True:
    try:
        val = input().split(" ")
        data.append((int(val[0]), int(val[1])))
    except EOFError:
        break

for i in range(len(data)):
    c, t = data[i]
    total_points_count = total_points_count + 1
    if c in count_per_cluster:
        count_per_cluster[c] = count_per_cluster[c] + 1
    else:
        count_per_cluster[c] = 1
    
    if t in count_per_truth:
        count_per_truth[t] = count_per_truth[t] + 1
    else:
        count_per_truth[t] = 1
    
    if c not in count_per_truth_given_cluster:
        count_per_truth_given_cluster[c] = {}
    if t not in count_per_truth_given_cluster[c]:
        count_per_truth_given_cluster[c][t] = 0
    count_per_truth_given_cluster[c][t] = count_per_truth_given_cluster[c][t] + 1
    
    for j in range(i+1, len(data)):
        c2, t2 = data[j]
        if c == c2 and t == t2:
            tp = tp + 1
        elif c == c2 and t != t2:
            fp = fp + 1
        elif c != c2 and t == t2:
            fn = fn + 1

hC = 0
pcs = [0] * len(count_per_cluster.keys())
pts = [0] * len(count_per_truth.keys())
for key, val in count_per_cluster.items():
    pC = val/total_points_count
    pcs[key] = pC
    hC = hC - pC * math.log2(pC)

hT = 0
for key, val in count_per_truth.items():
    pT = val/total_points_count
    pts[key] = pT
    hT = hT - pT * math.log2(pT)

I = 0
for kc,vc in count_per_truth_given_cluster.items():
    for kt, vt in count_per_truth_given_cluster[kc].items():
        p = vt/total_points_count
        pC
        I = I + p * math.log2(p/(pcs[kc] * pts[kt]))

NMI = I / math.sqrt(hC * hT)
J = tp / (tp + fn + fp)

print("{:.3f} {:.3f}".format(NMI,J))