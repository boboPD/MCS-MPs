def read_from_file(filename):
    db = []
    with open(filename, "r", encoding="utf8") as f:
        for line in f:
            db.append(line.split(" "))
    
    return db

def get_freq_itemset(db, minsup):
    item_to_count_map = {}
    for seq in db:
        for item in seq:
            if item in item_to_count_map:
                item_to_count_map[item] = item_to_count_map[item] + 1
            else:
                item_to_count_map[item] = 1
    
    freq_items = []
    for item, count in item_to_count_map.keys():
        if count >= minsup:
            freq_items.append(item)

    return freq_items

def get_projections(db, prefix):
    new_db = []
    for seq in db:
        first_occr = seq.index(prefix)
        if first_occr < len(seq):
            new_db.append(seq[first_occr+1:])
    
    return new_db

def prefixspan(db, minsup):
    freq_items = get_freq_itemset(db, minsup)
    seq_patterns = []
    for item in freq_items:
        proj_db = get_projections(db, item)
        sub_seq_patterns = prefixspan(proj_db, minsup)
        seq_patterns.append([item] + sub_seq_patterns)
    
    return seq_patterns