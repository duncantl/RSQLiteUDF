source("llvm4.R")

tm.ll = system.time({ d = dbGetQuery(db, "SELECT i, fib(i) from vals") })

fibr = function(n) if(n < 2) n else fibr(n-1) + fibr(n-2)
createSQLFunction(db, fibr, "fibr", nargs = 1L)
tm.r = system.time({ d2 = dbGetQuery(db, "SELECT i, fibr(i) from vals") })

#fibr manages to not work with integers
identical(d2[,2], d[,2])
identical(as.integer(d2[,2]), d[,2])

#
tm.r/tm.ll
#    user   system  elapsed 
#205.5283 302.5000 206.1188 


tm.ll.10 = system.time({ d2 = dbGetQuery(db, "SELECT i, fib(i) from vals LIMIT 10") })
tm.r.10 = system.time({ d2 = dbGetQuery(db, "SELECT i, fibr(i) from vals LIMIT 10") })

tm.r.10/tm.ll.10
# ratio of 200
