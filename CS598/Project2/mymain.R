library(lubridate)
library(tidyverse)
library(forecast)

preprocess = function(data){
  clean_data = select(data, Store, Dept, Weekly_Sales, Date)
  clean_data$Store = as.factor(clean_data$Store)
  clean_data$Dept = as.factor(clean_data$Dept)
  clean_data["wk"] = ifelse(year(data$Date) == 2010, week(data$Date)-1, week(data$Date))
  clean_data
}

mypredict = function(){
  if (t>1){
    #new_train = preprocess(new_train)
    train <<- train %>% add_row(new_train)
  }
  #else{
  #  train = preprocess(train)
  #}
  
  start_date <- ymd("2011-03-01") %m+% months(2 * (t - 1))
  end_date <- ymd("2011-05-01") %m+% months(2 * (t - 1))
  test_current <- test %>%
    filter(Date >= start_date & Date < end_date) %>%
    select(-IsHoliday)
  
  test_depts <- unique(test_current$Dept)
  test_pred <- NULL
  
  for(dept in test_depts){
    train_dept_data <- train %>% filter(Dept == dept)
    test_dept_data <- test_current %>% filter(Dept == dept)
    
    # no need to consider stores that do not need prediction
    # or do not have training samples
    train_stores <- unique(train_dept_data$Store)
    test_stores <- unique(test_dept_data$Store)
    test_stores <- intersect(train_stores, test_stores)
    
    for(store in test_stores){
      subset = train_dept_data %>% filter(Store == store)
      test_subset = test_dept_data %>% filter(Store == store) %>% arrange(Date)
      model = snaive(ts(subset$Weekly_Sales, start = 1, frequency = 52), 8)
      temp= test_subset %>% mutate(Weekly_Pred=model$model$future[1:nrow(test_subset)])
      if(is.null(test_pred)){
        test_pred = temp
      }
      else{
        test_pred = test_pred %>% add_row(temp)
      }
    }
  }
  
  return(test_pred)
}