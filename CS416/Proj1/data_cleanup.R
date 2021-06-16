library(dplyr)

options(stringsAsFactors = F)

data = readr::read_csv(file = "data/data.csv", col_types = cols(
                                  CountryCode = "c",
                                  IndicatorCode = "c",
                                  Year = "f",
                                  value = "d",
                                  IndicatorType = "f",
                                  IndicatorSubType = "f",
                                  Gender = "f"
))
country_data = readr::read_csv("data/country_data.csv",
                               col_types = cols(
                                 CountryCode = "f",
                                 Region = "f",
                                 IncomeGroup = "c",
                                 TableName = "c"
                               ))
#indicators = readr::read_csv("data/indicators.csv", col_types = cols(IndicatorCode = "f", name = "c"))

data$CountryCode = factor(data$CountryCode, levels = levels(country_data$CountryCode))

complete_data = inner_join(data, country_data, by = c("CountryCode"))
complete_data$IncomeGroup = factor(complete_data$IncomeGroup, levels = c("Low income", "Lower middle income", "Upper middle income", "High income"), ordered = T)

edu_data_hs = complete_data %>% filter(IndicatorSubType == "Higher Secondary")
edu_data_ls = complete_data %>% filter(IndicatorSubType == "Lower Secondary")
empl_data_ind = complete_data %>% filter(IndicatorSubType == "Industry")
empl_data_svc = complete_data %>% filter(IndicatorSubType == "Service")

scatter_plot_data = complete_data %>% group_by(IndicatorType, IncomeGroup, Year, CountryCode) %>% 
  summarise(mean_value=mean(value, na.rm = T)) %>% pivot_wider(names_from = IndicatorType, values_from=mean_value) %>%
  filter(!is.na(Employment) & !is.na(Education))
