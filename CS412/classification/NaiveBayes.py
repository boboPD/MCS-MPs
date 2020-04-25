training_data = []
test_data = []

priors = {}
cond_prob = {}
feature_names = []
attribute_count = 0

def read_input():
    global feature_names
    feature_names = [x for x in input().split(",")[1:-1]]
    global attribute_count
    attribute_count = len(feature_names)
    while True:
        try:
            data = [int(x) for x in input().split(",")[1:]]
            if data[-1] == -1:
                test_data.append(data)
            else:
                training_data.append(data)
        except EOFError:
            break
        except IndexError:
            break

def calculate_probabilities():
    class_counts = {h:0 for h in range(1,8)}

    for i in range(len(training_data)):
        class_counts[training_data[i][-1]] = class_counts[training_data[i][-1]] + 1

    for j in range(attribute_count):
        cond_prob[feature_names[j]] = {}

        if j == 12:
            cond_prob[feature_names[j]][0] = {k: 0 for k in range(1,8)}
            cond_prob[feature_names[j]][2] = {k: 0 for k in range(1,8)}
            cond_prob[feature_names[j]][4] = {k: 0 for k in range(1,8)}
            cond_prob[feature_names[j]][5] = {k: 0 for k in range(1,8)}
            cond_prob[feature_names[j]][6] = {k: 0 for k in range(1,8)}
            cond_prob[feature_names[j]][8] = {k: 0 for k in range(1,8)}
        else:
            cond_prob[feature_names[j]][0] = {i: 0 for i in range(1,8)}
            cond_prob[feature_names[j]][1] = {i: 0 for i in range(1,8)}

        for i in range(len(training_data)):
            label = training_data[i][-1]
            cond_prob[feature_names[j]][training_data[i][j]][label] = cond_prob[feature_names[j]][training_data[i][j]][label] + 1
    
    # Normalising the counts
    for key, value in class_counts.items():
        priors[key] = (value + 0.1)/(len(training_data) + 0.1*len(class_counts.keys()))
    
    for feature in feature_names:
        for countMap in cond_prob[feature].values():
            for class_type, count in countMap.items():
                countMap[class_type] = (count + 0.1)/(class_counts[class_type] + 0.1*attribute_count)

def classify():
    for row in test_data:
        probable_class = -1
        max_probability = 0.0

        for c in range(1,8):
            prob = priors[c]

            for i in range(0, attribute_count):
                prob = prob * cond_prob[feature_names[i]][row[i]][c]
            
            if prob > max_probability:
                probable_class = c
                max_probability = prob

        row[-1] = probable_class

read_input()
calculate_probabilities()
classify()

for row in test_data:
    if row[-1] == -1:
        raise ValueError("Unclassified!")
    else:
        print(str(row[-1]))