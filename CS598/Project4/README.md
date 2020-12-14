There are 3 main files:

1. __ui.R__: This contains the UI code for shiny.
1. __server.R__: This contains the server code for shiny.
1. __algo.R__: This is the file that contains the code for the algorithms of both system 1 and system 2. There are two functions in this file called `system1(user_rated, genre)` and system2(user_rated), corresponding to the 2 systems.

The code depends on the following libraries:

library(shiny)
library(shinydashboard)
library(recommenderlab)
library(ShinyRatingInput)
library(shinyjs)
library(recommenderlab)
library(dplyr)

All the required data needed to run the app is checked in to the repository. YOu should be able to just clone the repo and use `runApp()` in that directory to start the app locally.