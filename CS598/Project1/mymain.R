library(glmnet)
library(rpart)
library(dplyr)
library(xgboost)

options(stringsAsFactors = F)

recode_ordinals = function(df){
  quality = c(Excellent=5, Good=4, Typical=3, Fair=2, Poor=1)
  bsmt_lq_q = c(GLQ=6, ALQ=5, BLQ=4, Rec=3, LwQ=2, Unf=1, No_Basement=0)
  
  #Handling ordinal values
  df$Lot_Shape = recode(df$Lot_Shape, Regular=4, Slightly_Irregular=3, Moderately_Irregular=2, Irregular=1)
  df$Overall_Qual = recode(df$Overall_Qual, Very_Excellent=10, Excellent=9, Very_Good=8, Good=7, Above_Average=6, Average=5, Below_Average=4,
                           Fair=3, Poor=2, Very_Poor=1)
  df$Exter_Qual = recode(df$Exter_Qual, !!!quality)
  df$Exter_Cond = recode(df$Exter_Cond, !!!quality)
  df$Bsmt_Qual = recode(df$Bsmt_Qual, !!!quality, No_Basement=0)
  df$Heating_QC = recode(df$Heating_QC, !!!quality)
  df$Kitchen_Qual = recode(df$Kitchen_Qual, !!!quality)
  df$Fireplace_Qu = recode(df$Fireplace_Qu, !!!quality, No_Fireplace=0)
  df$Garage_Qual = recode(df$Garage_Qual, !!!quality, No_Garage=0)
  
  df$BsmtFin_Type_1 = recode(df$BsmtFin_Type_1, !!!bsmt_lq_q)
  df$BsmtFin_Type_2 = recode(df$BsmtFin_Type_2, !!!bsmt_lq_q)
  
  df$Bsmt_Exposure = recode(df$Bsmt_Exposure, Gd=4, Av=3, Mn=2, No=1, No_Basement=0)
  df$Electrical = recode(df$Electrical, SBrkr=5, FuseA=4, FuseF=3, FuseP=2, Mix=1, Unknown=0)
  df$Garage_Finish = recode(df$Garage_Finish, Fin=3, RFn=2, Unf=1, No_Garage=0)
  df$Functional = recode(df$Functional, Typ=7, Min1=6, Min2=5, Mod=4, Maj1=3, Maj2=2, Sev=1, Sal=0)
  
  df$Central_Air = ifelse(df$Central_Air == "Y", TRUE, FALSE)
  
  df
}

get_levels_for_categorical_vars = function(df){
  cat_vars = colnames(select(df, where(is.character)))
  training_lvls = list()
  for(v in cat_vars){
    lvls = sort(unique(df[, v]))
    lvls = gsub("[^A-Za-z0-9_]", "_", lvls) #getting rid of random chars in the strings
    training_lvls[[v]] = lvls
  }
  
  training_lvls
}

create_dummies = function(df, levels){
  cat_vars = colnames(select(df, where(is.character)))
  for(v in cat_vars){
    for(l in levels[[v]]){
      col_name = paste(v, l, sep = "_")
      df[col_name] = ifelse(df[, v]==l, 1, 0)
    }
    df = select(df, -all_of(v))
  }
  
  df
}

common_preprocessing = function(rawdata){
  cleandata = rawdata
  
  # Fixing a couple of columns
  cleandata$Year_Built = ifelse(cleandata$Year_Built > cleandata$Year_Sold, cleandata$Year_Sold, cleandata$Year_Built)
  cleandata$Garage_Yr_Blt = ifelse(is.na(cleandata$Garage_Yr_Blt), 0, cleandata$Garage_Yr_Blt)
  
  #Creating an age column instead of using Year_Built
  cleandata["Age"] = cleandata$Year_Sold - cleandata$Year_Built
  cleandata = select(cleandata, -Year_Built)
  
  cleandata = recode_ordinals(cleandata)
  
  cleandata
}

get_quantiles = function(df, winsor.vars){
  quantiles = list()
  for(var in winsor.vars){
    myquan = quantile(df[, var], probs = 0.95, na.rm = TRUE)
    quantiles[var] = myquan
  }
}

winsorise = function(df, quan){
  for(var in names(quan)){
    tmp = df[, var]
    tmp[tmp > quan[[var]]] = quan[[var]]
    df[, var] = tmp
  }
  
  df
}

get_predictions_xgboost = function(train, test){
  #dropping unwanted columns
  drop_vars = c("PID", "Garage_Area", "Garage_Cond", "Condition_2", "Bsmt_Cond", "Pool_Area", "Land_Slope", "Bldg_type", "Utilities", "Roof_Matl", "Heating", "Street", "Pool_QC", "Overall_Cond", "BsmtFin_SF_1", 
                "Bsmt_Unf_SF", "Bsmt_Half_Bath", "Latitude", "Longitude", "Misc_Feature", "Misc_Val", "Three_season_porch", "BsmtFin_SF_2")
  train = train[, !(colnames(train) %in% drop_vars)]
  
  #process train data
  train = common_preprocessing(train)
  
  winsor.vars = c("Lot_Frontage", "Lot_Area", "Mas_Vnr_Area", "Total_Bsmt_SF", "Second_Flr_SF", 'First_Flr_SF', "Gr_Liv_Area", "Wood_Deck_SF", "Open_Porch_SF", "Enclosed_Porch", "Screen_Porch")
  train_quans = get_quantiles(train, winsor.vars)
  train = winsorise(train, train_quans)
  
  train_lvls = get_levels_for_categorical_vars(train)
  train = create_dummies(train, train_lvls)
  
  train$Sale_Price = log(train$Sale_Price)
  
  train.matrix = as.matrix(select(train, -Sale_Price))
  train.output = as.vector(train$Sale_Price)
  
  #train model
  xgbmodel = xgboost(data = train.matrix, label = train.output, nrounds = 5000, max_depth=4, 
                     eta=0.05, subsample=0.75, gamma=0, verbose = F)
  
  #process test data
  test = test[, !(colnames(test) %in% drop_vars)]
  test = common_preprocessing(test)
  test = winsorise(test, train_quans)
  test = create_dummies(test, train_lvls)
  
  #return predictions
  predict(xgbmodel, as.matrix(test))
}

get_predictions_linear = function(train, test){
  drop_vars = c('Street', 'Utilities',  'Condition_2', 'Roof_Matl', 'Heating', 'Pool_QC', 'Misc_Feature', 'Low_Qual_Fin_SF', 'Pool_Area', 'Longitude','Latitude')
  train = train[, !(colnames(train) %in% drop_vars)]
  
  #process train data
  winsor.vars = c("Lot_Frontage", "Lot_Area", "Mas_Vnr_Area", "BsmtFin_SF_2", "Bsmt_Unf_SF", "Total_Bsmt_SF", "Second_Flr_SF", 'First_Flr_SF', "Gr_Liv_Area", 
                   "Garage_Area", "Wood_Deck_SF", "Open_Porch_SF", "Enclosed_Porch", "Three_season_porch", "Screen_Porch", "Misc_Val")
  train_lvls = get_levels_for_categorical_vars(train)
  train_quans = get_quantiles(train, winsor.vars)
  
  train = common_preprocessing(train)
  train = winsorise(train, train_quans)
  train = create_dummies(train, train_lvls)
  train$Sale_Price = log(train$Sale_Price)
  
  train.matrix = as.matrix(select(train, -Sale_Price))
  train.output = as.vector(train$Sale_Price)
  
  #training linear model
  cv.out <- cv.glmnet(train.matrix, train.output, alpha = 1)
  sel.vars <- predict(cv.out, type="nonzero", s = cv.out$lambda.1se)$X1
  cv.out <- cv.glmnet(train.matrix[, sel.vars], train.output, alpha = 0)
  
  #preprocess test data
  test = test[, !(colnames(test) %in% drop_vars)]
  test = common_preprocessing(test)
  test = winsorise(test, train_quans)
  test = create_dummies(test, train_lvls)
  
  as.vector(predict(cv.out, as.matrix(test[, sel.vars]), s=cv.out$lambda.min))
}

data <- read.csv("Ames_data.csv")
testIDs <- read.table("project1_testIDs.dat")
results = data.frame(xgb=rep(0,10), lasso=rep(0,10), time=rep(0,10))
for(j in 1:10){
  raw_train_data <- data[-testIDs[,j], ]
  raw_test_data <- data[testIDs[,j], ]
  test_y <- log(raw_test_data[, 83])
  raw_test_data <- raw_test_data[, -83]
  
  start_time = Sys.time()
  #pred_xgb = get_predictions_xgboost(raw_train_data, raw_test_data)
  pred_xgb = rep(0, 879)
  pred_lin = get_predictions_linear(raw_train_data, raw_test_data)
  end_time = Sys.time()
  
  err1 = sqrt(sum((pred_xgb-test_y)^2)/length(test_y))
  err2 = sqrt(sum((pred_lin-test_y)^2)/length(test_y))
  
  results[j, ] = c(err1, err2, (end_time - start_time))
}

#submission1 = data.frame(PID=raw_test_data[, "PID"], Sale_Price=exp(preds$xgb))
#submission2 = data.frame(PID=raw_test_data[, "PID"], Sale_Price=exp((preds$lasso)))

#write.csv(submission1, file = "mysubmission1.txt", row.names = F)
#write.csv(submission2, file = "mysubmission2.txt", row.names = F)

#print(preds$time)