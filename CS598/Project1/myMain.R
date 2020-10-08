library(glmnet)
library(rpart)
library(dplyr)

transform_types = function(df){
  quality = c(Excellent=5, Good=4, Typical=3, Fair=2, Poor=1)
  bsmt_lq_q = c(GLQ=6, ALQ=5, BLQ=4, Rec=3, LwQ=2, Unf=1, No_Basement=0)
  
  df = mutate(df, across(where(is.character), as.factor))
  df$Lot_Shape = recode(df$Lot_Shape, Regular=4, Slightly_Irregular=3, Moderately_Irregular=2, Irregular=1)
  df$Overall_Qual = recode(df$Overall_Qual, Very_Excellent=10, Excellent=9, Very_Good=8, Good=7, Above_Average=6, Average=5, Below_Average=4,
                           Fair=3, Poor=2, Very_Poor=1)
  df$Exter_Qual = recode(df$Exter_Qual, !!!quality)
  df$Exter_Cond = recode(df$Exter_Cond, !!!quality)
  df$Bsmt_Qual = recode(df$Bsmt_Qual, !!!quality)
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

train = read.csv("train.csv")

# Pre-processing
train$Year_Built = ifelse(train$Year_Built > train$Year_Sold, train$Year_Sold, Year_Built)
train["Age"] = train$Year_Sold - train$Year_Built
train$Garage_Yr_Blt = ifelse(is.na(train$Garage_Yr_Blt), 0, train$Garage_Yr_Blt)

#dropping unwanted columns
drop_vars = c("Garage_Area", "Garage_Cond", "Condition_2", "Bsmt_Cond", "Pool_Area", "Land_Slope", "Bldg_type", "Utilities", "Roof_Matl", "Heating", "Street", "Pool_QC", "Overall_Cond", "Year_Built", "BsmtFin_SF_1", 
              "Bsmt_Unf_SF", "Bsmt_Half_Bath", "Latitude", "Longitude", "Misc_Feature", "Misc_Val")
train = train[, !(colnames(train) %in% drop_vars)]

# fixing variable types
train = transform_types(train)

train