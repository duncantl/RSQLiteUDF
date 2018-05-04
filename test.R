# This requires RSQLite_1.0.0


#dyn.load("src/Rinit.so")
library(RSQLite)
library(RSQLiteUDF)

#db = dbConnect(SQLite(), "Date")
db = dbConnect(SQLite(), "dataexpo")

# Load RSQLiteUDF and the RSQLite extensions
sqliteExtension(db) # want the floor function from RSQLite extensions.

d = dbGetQuery(db, "SELECT surftemp FROM measure_table LIMIT 5")
d

#d = dbGetQuery(db, "SELECT surftemp, floor(surftemp), ifloor(surftemp) FROM measure_table LIMIT 5")
#print(head(d))



ptr = getNativeSymbolInfo("myfloorFunc")$address
createSQLFunction(db, ptr, "myfloor", nargs = 1L)

d = dbGetQuery(db, "SELECT surftemp, floor(surftemp), myfloor(surftemp) FROM measure_table LIMIT 5")
print(d)

f = function(x) x/2
trace(f)
createSQLFunction(db, f, "div2", nargs = 1L)
d = dbGetQuery(db, "SELECT surftemp, div2(surftemp) FROM measure_table LIMIT 5")
print(d)


if(FALSE) {
.Call("R_registerSQLFunc", db@Id, function(x) x/2, "div2", 1L)
.Call("R_registerSQLFunc", db@Id, function(x) x/2, "div2", 1L)
}


# Strings
createSQLFunction(db, nchar, "nchar", nargs = 1L)
d = dbGetQuery(db, "SELECT DISTINCT month, nchar(month) FROM date_table")
print(d)


createSQLFunction(db, function(x, y) x/2 + y, "foo", nargs = -1L)
d = dbGetQuery(db, "SELECT surftemp, foo(surftemp, 2) FROM measure_table LIMIT 5")
print(d)



createSQLFunction(db, function(x) as.integer(grepl("^[45]/", x)), "aprilMay", nargs = -1L)
d = dbGetQuery(db, "SELECT * FROM orders WHERE aprilMay(order_date)")

d = dbGetQuery(db, "SELECT surftemp, foo(surftemp, 2) FROM measure_table LIMIT 5")

###########################

# These two examples are very bad implementations of the sum and variance/correlation
# that do not deal with numerical inaccuracies that arise even in these  data sets.
# There are much better computational approaches.

gen =
function()
{
  total = 0
  count = 0L
  
  list( update = function(val) {
                    total <<- total + val
                    count <<- count + 1L
                 },
        value = function() total/count)
}

funs = gen()
createSQLAggregateFunction(db, funs$update, funs$value, "mean", nargs = 1L)
d = dbGetQuery(db, "SELECT mean(surftemp), AVG(surftemp) FROM measure_table")
print(d)




genCor =
function()
{
  xy = 0
  x = 0
  y = 0
  x2 = 0
  y2 = 0
  count = 0L
  
  list( update = function(a, b) {
                    xy <<- xy + a*b
                    x <<- x + a
                    y <<- y + b
                    x2 <<- x2 + a*a
                    y2 <<- y2 + b*b                    
                    count <<- count + 1L
                 },
        value = function()
                    (count * xy - x * y)/ (sqrt( (count - 1) * x2 - x^2) * sqrt( (count - 1) * y2 - y^2))
        )
}
funs = genCor()
createSQLAggregateFunction(db, funs$update, funs$value, "cor", nargs = 2L)
d = dbGetQuery(db, "SELECT cor(surftemp, temperature) FROM measure_table")
print(d)

tbl = dbReadTable(db, "measure_table")[, c("surftemp", "temperature")]
ans = cor(tbl[,1], tbl[,2])



