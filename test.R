
#dyn.load("src/Rinit.so")
library(RSQLite)
library(RSQLiteUDF)

#db = dbConnect(SQLite(), "Date")
db = dbConnect(SQLite(), "dataexpo")

sqliteExtension(db, getLoadedDLLs()[["RSQLiteUDF"]][["path"]])
initExtension(db)

d = dbGetQuery(db, "SELECT surftemp FROM measure_table LIMIT 5")
d

#d = dbGetQuery(db, "SELECT surftemp, floor(surftemp), ifloor(surftemp) FROM measure_table LIMIT 5")
#print(head(d))



ptr = getNativeSymbolInfo("myfloorFunc")$address

createSQLFunction(db, ptr, "myfloor", 1L)
d = dbGetQuery(db, "SELECT surftemp, floor(surftemp), myfloor(surftemp) FROM measure_table LIMIT 5")
print(d)


createSQLFunction(db, function(x) x/2, "div2", 1L)
d = dbGetQuery(db, "SELECT surftemp, div2(surftemp) FROM measure_table LIMIT 5")
print(d)


if(FALSE) {
.Call("R_registerSQLFunc", db@Id, function(x) x/2, "div2", 1L)
.Call("R_registerSQLFunc", db@Id, function(x) x/2, "div2", 1L)
}


createSQLFunction(db, nchar, "nchar", 1L)
d = dbGetQuery(db, "SELECT DISTINCT month, nchar(month) FROM date_table")
print(d)


createSQLFunction(db, function(x, y) x/2 + y, "foo", -1L)
d = dbGetQuery(db, "SELECT surftemp, foo(surftemp, 2) FROM measure_table LIMIT 5")
print(d)
