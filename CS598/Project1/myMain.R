library(glmnet)
library(rpart)
library(dplyr)

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

create_dummies_train = function(df){

  #Creating dummy variables
  cat_vars = colnames(select(df, where(is.character)))
  for(v in cat_vars){
    lvls = sort(unique(df[, v]))
    lvls = gsub("[^A-Za-z0-9_]", "_", lvls)
    training_lvls[[v]] <<- lvls
    for(l in lvls){
      col_name = paste(v, l, sep = "_")
      df[col_name] = ifelse(df[, v]==l, 1, 0)
    }
    df = select(df, -all_of(v))
  }
  
  df
}

create_dummies_test = function(df){
  cat_vars = colnames(select(df, where(is.character)))
  for(v in cat_vars){
    for(l in training_lvls[[v]]){
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
  
  #dropping unwanted columns
  drop_vars = c("Garage_Area", "Garage_Cond", "Condition_2", "Bsmt_Cond", "Pool_Area", "Land_Slope", "Bldg_type", "Utilities", "Roof_Matl", "Heating", "Street", "Pool_QC", "Overall_Cond", "Year_Built", "BsmtFin_SF_1", 
                "Bsmt_Unf_SF", "Bsmt_Half_Bath", "Latitude", "Longitude", "Misc_Feature", "Misc_Val", "Three_season_porch")
  cleandata = cleandata[, !(colnames(cleandata) %in% drop_vars)]
  
  cleandata = recode_ordinals(cleandata)
  
  cleandata
}

winsorise = function(df){
  winsor.vars <- c("Lot_Frontage", "Lot_Area", "Mas_Vnr_Area", "BsmtFin_SF_2", "Total_Bsmt_SF", "Second_Flr_SF", 'First_Flr_SF', "Gr_Liv_Area", "Wood_Deck_SF", "Open_Porch_SF", "Enclosed_Porch", "Screen_Porch")
  quan.value <- 0.95
  for(var in winsor.vars){
    tmp <- df[, var]
    myquan <- quantile(tmp, probs = quan.value, na.rm = TRUE)
    tmp[tmp > myquan] <- myquan
    df[, var] <- tmp
  }
  
  df
}

# Read and pre-process training data
training_lvls = list() #list to hold the levels of the factors in the training data so it can be used for creating the dummies in test data
train = read.csv("train.csv")
train = common_preprocessing(train)
train = winsorise(train)
train = create_dummies_train(train)
train$Sale_Price = log(train$Sale_Price)

#Create the models

#Read and pre-process test data
test_data = read.csv("test.csv")
test_data = common_preprocessing(test_data)
test_data = create_dummies_test(test_data)
test_out = read.csv("test_y.csv")
test_out$Sale_Price = log(test_out$Sale_Price)