library(text2vec)
library(dplyr)
library(xgboost)

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
train <- read.table("train.tsv", stringsAsFactors = FALSE, header = TRUE)

dtm_train = create_dtm_matrix(train, myvocab)

#####################################
#
# Train a binary classification model
#
#####################################
#training_params = list(objective="binary:logistic", eta=0.1, max_depth=3, gamma=1, colsample_bytree=1, min_child_weight=2, subsample=0.75)
#model = xgboost(data = dtm_train, label = train$sentiment, nrounds = 2000, params = training_params, verbose = F)
model = glmnet::glmnet(as.matrix(dtm_train), train$sentiment, family = "binomial", lambda = 0.05785583, alpha = 0)

#####################################
# Compute prediction 
# Store your prediction for test data in a data frame
# "output": col 1 is test$id
#           col 2 is the predited probabilities
#####################################

test <- read.table("test.tsv", stringsAsFactors = FALSE, header = TRUE)

dtm_test = create_dtm_matrix(test, myvocab)

test.y= read.table("test_y.tsv", header = T, stringsAsFactors = F)
preds = predict(model, dtm_test, type="response")
output = data.frame(id=test$id, prob=preds[, "s0"])
write.table(output, file = "mysubmission.txt", row.names = FALSE, sep='\t')