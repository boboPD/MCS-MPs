library(recommenderlab)
library(dplyr)

ratings = read.csv("./data/ratings.dat", sep = ":", colClasses = c('integer', 'NULL'), header = F)
colnames(ratings) = c('UserID', 'MovieID', 'Rating', 'Timestamp')

recom_hy = NULL

movies = readLines('./data/movies.dat')
movies = strsplit(movies, split = "::", fixed = TRUE, useBytes = TRUE)
movies = matrix(unlist(movies), ncol = 3, byrow = TRUE)
movies = data.frame(movies, stringsAsFactors = FALSE)
colnames(movies) = c('MovieID', 'Title', 'Genres')
movies$MovieID = as.integer(movies$MovieID)
movies$Title = iconv(movies$Title, "latin1", "UTF-8")
small_image_url = "https://liangfgithub.github.io/MovieImages/"
movies$image_url = sapply(movies$MovieID, function(x) paste0(small_image_url, x, '.jpg?raw=true'))

system1 = function(user_rated, genre){
  filMov = movies[grep(genre, movies$Genres, fixed = T), ]
  top_movies= ratings %>% inner_join(filMov, by="MovieID") %>% group_by(MovieID, Genres) %>% summarise(rating=mean(Rating, na.rm=T), num_of_ratings=n()) %>% filter(rating > 3.5 & num_of_ratings > 50) %>% ungroup()
  
  #Finding the set of genres of movies highly rated by the user
  genres_user_rated = user_rated %>% filter(Rating > 3) %>% inner_join(movies, by="MovieID") %>% select(MovieID, Genres)
  g = unlist(lapply(genres_user_rated$Genres, strsplit, split="|", fixed = T))
  genres_of_user_rated_movies = g[!duplicated(g)]
  
  #calculating the number of genres that each movie has in common with the ones user has rated highly
  genre_set1 = strsplit(top_movies$Genres, split = "|", fixed = TRUE)
  top_movies["common_genre_cnt"] = unlist(lapply(lapply(genre_set1, intersect, y=genres_of_user_rated_movies), length))
  
  top_movies %>% mutate(score=(0.25*common_genre_cnt + rating)) %>% select(-Genres, -num_of_ratings) %>% arrange(desc(score)) %>% top_n(10)
}

system2 = function(user_rated){
  
  if(is.null(recom_hy)){
    #train the model 1 time only
    i = paste0('u', ratings$UserID)
    j = paste0('m', ratings$MovieID)
    x = ratings$Rating
    tmp = data.frame(i, j, x, stringsAsFactors = T)
    Rmat = sparseMatrix(as.integer(tmp$i), as.integer(tmp$j), x = tmp$x)
    rownames(Rmat) = levels(tmp$i)
    colnames(Rmat) = levels(tmp$j)
    Rmat = new('realRatingMatrix', data = Rmat)
    
    recom_hy <<- HybridRecommender(
      Recommender(Rmat, method="POPULAR"),
      Recommender(Rmat, method="UBCF", parameter=list(nn=30)),
      weights = c(0.3, 0.7)
    )
  }
  
  user_rated$newMovieID = paste0('m', user_rated$MovieID)
  idxs = base::match(user_rated$newMovieID, levels(tmp$j))
  user_rating_mat = sparseMatrix(rep(1, length(idxs)), idxs, x=user_rated$Rating, dims = c(1, 3706))
  
  testuser = new('realRatingMatrix', data = user_rating_mat)
  colnames(testuser)=colnames(Rmat)
  p = as(predict(recom_hy, testuser, n=10), "list")[[1]]
  
  as.integer(substr(p, 2, nchar(p)))
}