library(pROC)

aucs=list()
for(i in 1:5){
  folder = paste("./split", i, sep="_")
  file.copy("mymain.R", paste(folder, "mymain.R", sep="/"), overwrite = T)
  file.copy("myvocab.txt", paste(folder, "myvocab.txt", sep="/"), overwrite = T)
  setwd(folder)
  source("mymain.R")
  test.y <- read.table("test_y.tsv", header = TRUE)
  pred <- read.table("mysubmission.txt", header = TRUE)
  pred <- merge(pred, test.y, by="id")
  roc_obj <- roc(pred$sentiment, pred$prob)
  aucs[paste("split", i, sep="_")] = pROC::auc(roc_obj)
  setwd("D:/repos/MCS-MPs/CS598/Project3")
}