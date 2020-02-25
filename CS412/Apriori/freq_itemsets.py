import apriori

def read_db_into_memory(filename):
    db = []

    with open(filename, "r", encoding="utf8") as f:
        for line in f.readlines():
            categories = [x.strip() for x in line.split(";")]
            db.append(sorted(categories))
    
    return db

def write_freq_itemsets_to_file(list_of_k_itemsets, filename):
    with open(filename, "w", encoding="utf8") as f:
        for kitemset in list_of_k_itemsets:
            for itemset, supp in kitemset.items():
                f.write(f"{supp}:{str(itemset)}\n")

db = read_db_into_memory("categories.txt")
minsup = 0.01 * len(db)

freq_itemsets = apriori.apriori(db, minsup, 10000)
write_freq_itemsets_to_file(freq_itemsets, "patterns.txt")
