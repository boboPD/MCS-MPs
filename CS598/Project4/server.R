source("algo.R")

get_user_ratings = function(value_list) {
    dat = data.table(MovieID = sapply(strsplit(names(value_list), "_"), 
                                      function(x) ifelse(length(x) > 1, x[[2]], NA)),
                     Rating = unlist(as.character(value_list)))
    dat = dat[!is.null(Rating) & !is.na(MovieID)]
    dat[Rating == " ", Rating := 0]
    dat[, ':=' (MovieID = as.numeric(MovieID), Rating = as.numeric(Rating))]
    dat = dat[Rating > 0]
}

user_ratings = c()

shinyServer(function(input, output, session) {
    # show the books to be rated
    output$ratings <- renderUI({
        num_rows <- 20
        num_movies <- 6 # movies per row
        
        lapply(1:num_rows, function(i) {
            list(fluidRow(lapply(1:num_movies, function(j) {
                list(box(width = 2,
                         div(style = "text-align:center", img(src = movies$image_url[(i - 1) * num_movies + j], height = 150)),
                         div(style = "text-align:center", strong(movies$Title[(i - 1) * num_movies + j])),
                         div(style = "text-align:center; font-size: 150%; color: #f0ad4e;", ratingInput(paste0("select_", movies$MovieID[(i - 1) * num_movies + j]), label = "", dataStop = 5)))) #00c0ef
            })))
        })
    })
    
    #Accept user ratings
    observeEvent(input$subRatings, {
        js$collapse("b1")
        js$collapse("b2")
        js$collapse("b3")
        
        # get the user's rating data
        value_list <- reactiveValuesToList(input)
        user_ratings <<- get_user_ratings(value_list)
    })
    
    #Show system 1 recommendations
    sys1recom = observeEvent(input$btn1, {
        recom_result = system1(user_ratings, input$selGenre)
        finaldata = inner_join(recom_result, movies, by="MovieID")
        
        # display the recommendations
        output$results1 <- renderUI({
            num_rows <- 2
            num_movies <- 5
            
            lapply(1:num_rows, function(i) {
                list(fluidRow(lapply(1:num_movies, function(j) {
                    idx = (i - 1) * num_movies + j
                    box(width = 2, status = "success", solidHeader = TRUE, title = paste0("Rank ", idx),
                        
                        div(style = "text-align:center", 
                            a(img(src = finaldata$image_url[idx], height = 150))
                        ),
                        div(style="text-align:center; font-size: 100%", 
                            strong(finaldata$Title[idx])
                        )
                        
                    )        
                }))) # columns
            }) # rows
            
        }) # renderUI function
    })
    
    # Calculate recommendations when the sbumbutton is clicked
    df <- eventReactive(input$btn, {
        withBusyIndicatorServer("btn", { # showing the busy indicator
            # hide the rating container
            useShinyjs()
            jsCode <- "document.querySelector('[data-widget=collapse]').click();"
            runjs(jsCode)
            
            
            
            user_results = (1:10)/10
            user_predicted_ids = 1:10
            recom_results <- data.table(Rank = 1:10, 
                                        MovieID = movies$MovieID[user_predicted_ids], 
                                        Title = movies$Title[user_predicted_ids], 
                                        Predicted_rating =  user_results)
            
        }) # still busy
        
    }) # clicked on button
    
    
    # display the recommendations
    output$results2 <- renderUI({
        num_rows <- 2
        num_movies <- 5
        recom_result <- df()
        
        lapply(1:num_rows, function(i) {
            list(fluidRow(lapply(1:num_movies, function(j) {
                box(width = 2, status = "success", solidHeader = TRUE, title = paste0("Rank ", (i - 1) * num_movies + j),
                    
                    div(style = "text-align:center", 
                        a(img(src = movies$image_url[recom_result$MovieID[(i - 1) * num_movies + j]], height = 150))
                    ),
                    div(style="text-align:center; font-size: 100%", 
                        strong(movies$Title[recom_result$MovieID[(i - 1) * num_movies + j]])
                    )
                    
                )        
            }))) # columns
        }) # rows
        
    }) # renderUI function
    
}) # server function