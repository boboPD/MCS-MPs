library(text2vec)
library(dplyr)

clean_reviews <- function(review){
  no_html = gsub('<.*?>', ' ', review)
  tolower(no_html)
}

create_dtm_matrix = function(data, vocab){
  itr = itoken(data$review, 
                    preprocessor = clean_reviews, 
                    tokenizer = word_tokenizer, 
                    ids = data$id,
                    progressbar = FALSE)
  
  create_dtm(itr, vocab_vectorizer(create_vocabulary(vocab, ngram=c(1,2))))
}

#####################################
# Load your vocabulary and training data
#####################################
myvocab <- scan(file = "myvocab.txt", what = character())
#train <- read.table("train.tsv", stringsAsFactors = FALSE, header = TRUE)

dtm_train = create_dtm_matrix(train, myvocab)

#####################################
#
# Train a binary classification model
#
#####################################

model = xgboost(data = dtm_train, label = train$sentiment, nrounds = 2000, 
                params = list(objective="reg:logistic"), verbose = F)

#####################################
# Compute prediction 
# Store your prediction for test data in a data frame
# "output": col 1 is test$id
#           col 2 is the predited probabilities
#####################################

#test <- read.table("test.tsv", stringsAsFactors = FALSE, header = TRUE)

dtm_test = create_dtm_matrix(test, myvocab)

preds = predict(model, dtm_test)
print(pROC::auc(test.y$sentiment, preds))
#write.table(output, file = "mysubmission.txt", row.names = FALSE, sep='\t')