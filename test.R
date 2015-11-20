dyn.load("src/Rinit.so")
library(RSQLite)

#db = dbConnect(SQLite(), "Date")
db = dbConnect(SQLite(), "dataexpo")

sqliteExtension(db, "src/Rinit.so")
initExtension(db)

d = dbGetQuery(db, "SELECT surftemp FROM measure_table LIMIT 5")
d

d = dbGetQuery(db, "SELECT surftemp, floor(surftemp), ifloor(surftemp) FROM measure_table LIMIT 5")
print(head(d))



ptr = getNativeSymbolInfo("myfloorFunc")$address
.Call("R_registerSQLFunc", db@Id, ptr, "myfloor", 1L)

d = dbGetQuery(db, "SELECT surftemp, floor(surftemp), myfloor(surftemp) FROM measure_table LIMIT 5")
print(d)


if(FALSE) {
.Call("R_registerSQLFunc", db@Id, function(x) x/2, "div2", 1L)
d = dbGetQuery(db, "SELECT surftemp, div2(surftemp) FROM measure_table LIMIT 5")
}