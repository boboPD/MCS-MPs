import collections
from timeit import default_timer as timer

def write_to_file(patterns):
    with open("patterns.txt", "w", encoding="utf8") as f:
        for pattern, count in patterns.items():
            f.write(f"{str(count)}:{pattern}\n")

def read_from_file(filename):
    db = []
    with open(filename, "r", encoding="utf8") as f:
        for line in f:
            db.append(line.strip().split(" "))
    
    return db

def get_freq_1_itemset(db, minsup):
    item_to_index_map = {}
    item_to_count = {}
    wordset = set()
    for row, seq in enumerate(db):
        wordset.clear()
        for col, item in enumerate(seq):
            if item not in wordset:
                wordset.add(item)
                if item not in item_to_count:
                    item_to_count[item] = 1
                else:
                    item_to_count[item] = item_to_count[item] + 1
            if item in item_to_index_map:
                item_to_index_map[item].append((row, col))
            else:
                item_to_index_map[item] = [(row, col)]
    
    freq_items = {item: (index_list, item_to_count[item]) for item, index_list in item_to_index_map.items() if item_to_count[item] >= minsup}
    return freq_items

def mine_proj_db(db, index_list, prefix, minsup):
    item_positions = {}
    item_counts = {}
    prev_row = -1
    distinct_words_in_row = set()
    for row, col in index_list:
        if row >= len(db) or col >=  len(db[row]):
            continue
        word = db[row][col]

        if row != prev_row:
            distinct_words_in_row.clear()
            prev_row = row

        if word not in distinct_words_in_row:
            distinct_words_in_row.add(word)
            if word not in item_counts:
                item_counts[word] = 1
            else:
                item_counts[word] = item_counts[word] + 1
        
        if word not in item_positions:
            item_positions[word] = [(row, col)]
        else:
            item_positions[word].append((row, col))
    
    freq_items = {f"{prefix};{item}": (item_positions[item], item_counts[item]) for item in item_counts if item_counts[item] >= minsup}
    return freq_items

def prefixspan(db, minsup):
    freq_items = get_freq_1_itemset(db, minsup)
    seq_patterns = {}
    for word in freq_items.keys():
        (_, count) = freq_items[word]
        seq_patterns[word] = count

    pending_itemsets = collections.deque()
    pending_itemsets.append(freq_items)
    while len(pending_itemsets) > 0:
        curr_freq_items = pending_itemsets.popleft()
        for item, (index_list, count) in curr_freq_items.items():
            next_idxs = [(row, col+1) for row, col in index_list]
            next_freq_items = mine_proj_db(db, next_idxs, item, minsup)
            for pattern in next_freq_items.keys():
                (_, count) = next_freq_items[pattern]
                seq_patterns[pattern] = count
            if len(next_freq_items) > 0:
                pending_itemsets.append(next_freq_items)
    
    return seq_patterns

data = read_from_file("reviews_sample.txt")
rel_min_sup = 0.01
start = timer()
ans = prefixspan(data, len(data) * rel_min_sup)
end = timer()
print(end-start)
write_to_file(ans)