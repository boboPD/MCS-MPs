def read_from_file(filename):
    db = []
    with open(filename, "r", encoding="utf8") as f:
        for line in f:
            db.append(line.split(" "))
    
    return db

def get_1_freq_itemset(db, minsup):
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
    return [seq[seq.index(prefix)+1:] for seq in db]

def prefixspan(db, minsup):
    