## ui.R
library(shiny)
library(shinydashboard)
library(recommenderlab)
library(ShinyRatingInput)
library(data.table)
library(shinyjs)
library(readr)

source('helpers.R')

jscode <- "
shinyjs.collapse = function(boxid) {
$('#' + boxid).closest('.box').find('[data-widget=collapse]').click();
}
"
genres = readLines("./data/genres.txt")

userRatingUI = function(){
  fluidRow(
    box(id="b2", width = 12, title = "Rate as many movies as possible", status = "info", solidHeader = TRUE, collapsible = TRUE,
        div(class = "rateitems",
            uiOutput('ratings')
        ),
        br(),
        actionButton(inputId = "subRatings", label = "Submit", class = "btn-primary", color="white")
    )
  )
}

system1UI = function(){
  fluidRow(
    useShinyjs(),
    box(id="b1",
      width = 12, status = "info", solidHeader = TRUE, collapsible = T, collapsed = T,
      title = "System 1: Discover movies you might like based on genre",
      br(),
      selectInput("selGenre", "Select a genre:", choices = genres),
      withBusyIndicatorUI(
        actionButton("btn1", "Get recommendations", class = "btn-primary", color="white")
      ),
      br(),
      tableOutput("results1")
    )
  )
}

system2UI = function(){
  fluidRow(
     useShinyjs(),
     extendShinyjs(text = jscode, functions = c("collapse")),
     box(id="b3",
       width = 12, status = "info", solidHeader = TRUE, collapsible = T, collapsed = T,
       title = "System 2: Discover movies you might like",
       br(),
       withBusyIndicatorUI(
         actionButton("btn2", "Get recommendations", class = "btn-primary", color="white")
       ),
       br(),
       tableOutput("results2")
     )
  )
}

dashboardPage(
      skin = "blue",
      dashboardHeader(title = "Movie Recommender"),
      
      dashboardSidebar(disable = TRUE),

      dashboardBody(includeCSS("./css/movies.css"),
          h4("Please click on the submit button once you have finished rating."),
          userRatingUI(),
          system1UI(),
          system2UI()
      )
)

