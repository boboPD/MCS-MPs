library(lubridate)
library(tidyverse)
library(forecast)
library(splines)
library(reshape)

preprocess = function(train, test){
  test.dates <- unique(test$Date)
  num.test.dates <- length(test.dates)
  all.stores <- unique(test$Store)
  num.stores <- length(all.stores)
  test.depts <- unique(test$Dept)
  test.depts <- test.depts[length(test.depts):1]
  forecast.frame <- data.frame(Date=rep(test.dates, num.stores), Store=rep(all.stores, each=num.test.dates))
  forecast.frame["wk"] <- as.factor(week(forecast.frame$Date))
  train.dates <- unique(train$Date)
  num.train.dates <- length(train.dates)
  train.frame <- data.frame(Date=rep(train.dates, num.stores), Store=rep(all.stores, each=num.train.dates))
  train.frame["wk"] <- as.factor(week(train.frame$Date))
  
  return(list(t=train.frame, f=forecast.frame))
}

get_preds_snaive = function(trainset, testset){
  model = snaive(ts(trainset$Weekly_Sales, start = 1, frequency = 52), 8)
  testset %>% mutate(Weekly_Pred=model$model$future[1:nrow(testset)])
}

get_preds_spline = function(trainset, testset){
  if(length(unique(trainset$wk)) < 4){
    result = testset %>% mutate(Weekly_Pred=mean(trainset$Weekly_Sales))
  }
  else{
    model = smooth.spline(trainset$wk, trainset$Weekly_Sales, df=20)
    preds = predict(model, testset$wk)
    result = testset %>% mutate(Weekly_Pred=preds$y)
  }
  
  return(result)
}

get_preds_tslm = function(trainset, testset){
  #print(testset)
  y = ts(trainset$Weekly_Sales, frequency = 52)
  model = tslm(y ~ trend + season)
  preds = forecast(model, h=nrow(testset))
  
  testset %>% mutate(Weekly_Pred=as.numeric(preds$mean))
}

get_preds_lm = function(trainset, testset){
  trainset$wk = as.factor(trainset$wk)
  trainset["Yr"] = year(trainset$Date)
  
  model = lm(Weekly_Sales ~ Yr+wk, trainset)
  
  testset$wk = as.factor(testset$wk)
  testset["Yr"] = year(testset$Date)
  
  testset %>% mutate(Weekly_Pred=predict(model, testset))
}

postprocess = function(predictions){
  g = cast(predictions, wk~Store, value = "Weekly_Pred")
  holiday <- filter(g, wk %in% 48:52) %>% select(-wk)
  baseline <- mean(rowMeans(holiday[c(1, 5), ], na.rm=TRUE))
  surge <- mean(rowMeans(holiday[2:4, ], na.rm=TRUE))
  
  if(is.finite(surge/baseline) & surge/baseline > 1.1){
    shifted.sales <- (6/7) * holiday
    shifted.sales[2:5, ] <- shifted.sales[2:5, ] + (1/7) * holiday[1:4, ]
    shifted.sales[1, ] <- holiday[1, ]
    g[5:9, 2:46] = shifted.sales
  }
  
  inner_join(predictions, melt(g), by=c("wk", "Store")) %>% select(-Weekly_Pred) %>% dplyr::rename(Weekly_Pred=value)
}

mypredict = function(){
  if (t>1){
    train <<- train %>% add_row(new_train)
  }
  
  start_date <- ymd("2011-03-01") %m+% months(2 * (t - 1))
  end_date <- ymd("2011-05-01") %m+% months(2 * (t - 1))
  
  test_current <- test %>%
    filter(Date >= start_date & Date < end_date) %>%
    select(-IsHoliday)
  
  test_depts <- unique(test_current$Dept)
  test_pred <- NULL
  
  frames = preprocess(train, test_current)
  train.frame = frames$t
  forecast.frame = frames$f
  
  for(d in test_depts){
    tr.d <- train.frame
    tr.d <- plyr::join(tr.d, train[train$Dept==d, c('Store','Date', 'Weekly_Sales')], by=c('Store','Date'))
    tr.d["Dept"] <- d
    fc.d <- forecast.frame
    temp = NULL
    
    stores = unique(tr.d$Store)
    for(store in stores){
      store.train <- filter(tr.d, Store==store)
      if(nrow(store.train) > sum(is.na(store.train$Weekly_Sales))){
        store.train[is.na(store.train$Weekly_Sales), "Weekly_Sales"] <- mean(store.train$Weekly_Sales, na.rm = T)
        store.test <- filter(fc.d, Store==store)
        store.test["Dept"] <- d
        res = get_preds_tslm(store.train, store.test)
        if(is.null(temp)){
          temp = res
        }
        else{
          temp = temp %>% add_row(res)
        }
      }
    }
    if(t == 5 & d != 65){
      temp = postprocess(temp)
    }
    
    if(is.null(test_pred)){
      test_pred = temp
    }
    else{
      test_pred = test_pred %>% add_row(temp)
    }
    
  }
  
  return(test_pred)
}

