#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

regions = list("All","Latin America & Caribbean","South Asia","Sub-Saharan Africa",
               "Europe & Central Asia","Middle East & North Africa","East Asia & Pacific",
               "North America")
incgrps = c("Low income", "Lower middle income", "Upper middle income", "High income")

mainPanelContent = function(){
  tabsetPanel(
    tabPanel("Visualizations",
             wellPanel(
               fluidRow(
                 selectInput("region", "Region", choices = regions, multiple = F)
               ),
               fluidRow(tags$h4("Trend of education over time")),
               fluidRow(plotOutput("edu_curves")),
               tags$br(),
               fluidRow(
                 column(3, offset = 3, checkboxInput("split", "Split by income group")),
                 column(3, radioButtons("edulvl", label = "Education Level:", choices = c("Higher Secondary", "Lower Secondary"), inline = T))
               ),
               fluidRow(tags$h4("Trend of employment over time")),
               fluidRow(
                 column(6, plotOutput("emplInd")),
                 column(6, plotOutput("emplSvc"))
               )
             ),
             fluidRow(tags$hr()),
             wellPanel(
               fluidRow(tags$h4("Relation between education and employment")),
               fluidRow(plotOutput("edu_empl_scatter")),
               fluidRow(
                 column(4, offset = 4, sliderInput("yearslider", "Year", min = 2000, max = 2018, step = 1, value = 2000, animate = T))
               )
             )
    ),
    tabPanel("Raw Data",
             inputPanel(
               selectInput("rawdata_region", "Region", choices = regions[-1], multiple = F),
               selectInput("rawdata_incgrp","Income Group", choices = incgrps, multiple = T, selected = incgrps),
               selectInput("rawdata_gender", "Gender", choices = c("Male", "Female"), multiple = T, selected = c("Male", "Female"))
             ),
             tags$br(),
             dataTableOutput("rawdatatbl")
    )
  )
}

sideBarContent = function(){
  includeMarkdown("resources/details.md")
}

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  titlePanel(title = "Visualising the correlation between education and employment"),
  sidebarLayout(
    sidebarPanel(sideBarContent(), width = 2),
    mainPanel(mainPanelContent(), width = 10)
  )
))
