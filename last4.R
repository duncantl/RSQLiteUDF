library(RSQLite)
library(RSQLiteUDF)

db = dbConnect(SQLite(), "~/Data/IMDB/imdbpy.db")
createSQLFunction(db, "lastNChars", 2L)


system.time({ a <- dbGetQuery(db, "SELECT lastNChars(info, 4) FROM movie_info WHERE info_type_id = 41;")})

