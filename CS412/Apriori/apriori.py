from itemset import ItemSet

def apriori(data, minsup, n):
    freq_itemsets = []      #list of dictionaries (<itemset, support>)
    itemsets_1 = get_freq_1_itemsets(data, minsup)
    freq_itemsets.append(itemsets_1)

    for i in range(2, n+1):
        candidates = generate_candidate_itemsets(list(freq_itemsets[-1].keys()), i)
        if len(candidates) == 0:
            break
        supports = get_itemset_support(data, candidates)
        freq_itemsets.append(prune_itemsets(supports, minsup))
    
    return freq_itemsets

def generate_candidate_itemsets(freq_itemsets_prev, n):
    candidates = []

    if n == 2:
        for i in range(len(freq_itemsets_prev)):
            for j in range(i+1, len(freq_itemsets_prev)):
                new_itemset = [freq_itemsets_prev[i].items[0], freq_itemsets_prev[j].items[0]]
                candidates.append(ItemSet(sorted(new_itemset)))
    else:
        for i in range(len(freq_itemsets_prev)):
            for j in range(i+1, len(freq_itemsets_prev)):
                itemset1 = freq_itemsets_prev[i].items
                itemset2 = freq_itemsets_prev[j].items

                print(str(itemset1) + "\n")
                print(str(itemset2) + "\n")

                joinable = True
                for k in range(n-2):
                    if itemset1[k] != itemset2[k]:
                        joinable = False
                        break
                
                if joinable and (itemset1[n-2] < itemset2[n-2]):  #n-2 because of 0 index
                    new_itemset = itemset1[:n-2]
                    new_itemset.append(itemset1[n-2])
                    new_itemset.append(itemset2[n-2])
                    candidates.append(ItemSet(sorted(new_itemset)))
    
        print(str(candidates) + "\n\n")
    return candidates

def get_itemset_support(db, cand):
    itemset_supp_map = {}
    for cand_itemset in cand:
        for tx in db:
            if all([item in tx for item in cand_itemset.items]):
                if cand_itemset in itemset_supp_map:
                    itemset_supp_map[cand_itemset] = itemset_supp_map[cand_itemset] + 1
                else:
                    itemset_supp_map[cand_itemset] = 1
    
    return itemset_supp_map

def get_freq_1_itemsets(db, minsup):
    map = {}
    for tx in db:
        for item in tx:
            obj = ItemSet([item])
            if obj in map:
                map[obj] = map[obj] + 1
            else:
                map[obj] = 1
    
    return prune_itemsets(map, minsup)

def prune_itemsets(itemsets_support_map, min_sup):
    pruned_map = {}
    for itemset, support in itemsets_support_map.items():
        if support >= min_sup:
            pruned_map[itemset] = support
    
    return pruned_map