#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)

source("data_cleanup.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    
    filtered_edu_data = reactive({
        
        temp = if(input$edulvl == "Higher Secondary") edu_data_hs else edu_data_ls
        if(input$region != "All"){
            temp %>% filter(Region == input$region)
        }
        else{
            temp
        }
    })
    
    output$edu_curves <- renderPlot({
        
        filtered_edu_summary = filtered_edu_data() %>% group_by(Gender, Year, IncomeGroup) %>% summarise(mean_val = mean(value, na.rm = T))
        
        p = ggplot(filtered_edu_summary) + geom_smooth(aes(x=Year, y=mean_val, colour=Gender, group=Gender), se=F) +
            theme(legend.position = "bottom") + ylab("Percentage of population")
        
        if(input$split){
            p + facet_wrap(~IncomeGroup)
        }
        else{
            p
        }
    })
    
    output$emplInd = renderPlot({
        if(input$region != "All"){
            temp = filter(empl_data_ind, Region == input$region)
        }
        else{
            temp = empl_data_ind
        }
        
        temp = temp %>% group_by(Gender, Year) %>% summarise(mean_val = mean(value, na.rm = T))
        ggplot(temp) + geom_smooth(aes(x=Year, y=mean_val, colour=Gender, group=Gender), se=F) + theme(legend.position = "bottom") +
            ggtitle("Population employed in Industry") + ylab("Percentage of population")
    })
    
    output$emplSvc = renderPlot({
        if(input$region != "All"){
            temp = filter(empl_data_svc, Region == input$region)
        }
        else{
            temp = empl_data_svc
        }
        
        temp = temp %>% group_by(Gender, Year) %>% summarise(mean_val = mean(value, na.rm = T))
        ggplot(temp) + geom_smooth(aes(x=Year, y=mean_val, colour=Gender, group=Gender), se=F) + theme(legend.position = "bottom") +
            ggtitle("Population employed in services sector") + ylab("Percentage of population")
    })
    
    
    output$edu_empl_scatter = renderPlot({
        ggplot(filter(scatter_plot_data, Year==input$yearslider)) + geom_point(aes(Education, Employment, colour=IncomeGroup), size = 10, alpha=0.6) +
            scale_colour_manual("Income Group", values = c("red", "orange", "green", "darkgreen")) +
            ylab("Average % of employment across sectors") + xlab("Average % of population having at least lower secondary education")
    })
    
    output$rawdatatbl = renderDataTable({
        complete_data %>% 
            filter(Region == input$rawdata_region & IncomeGroup %in% input$rawdata_incgrp & Gender %in% input$rawdata_gender) %>%
            rename(Country=TableName) %>% select(-IndicatorCode, -CountryCode) %>% select(Country, everything())
    })
})
