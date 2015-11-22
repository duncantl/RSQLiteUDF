# If we run this by itself, it segfaults.
# If we run this after source("test.R"), it works.
#

library(RSQLite)
library(RSQLiteUDF)



library(RLLVMCompile)
f = function(x) {
        printf("[f] %lf\n", x)
        x + 1
    }
cfun = compileFunction(f, DoubleType, list(DoubleType))

.llvm(cfun, 3)

#!!! But we need to generate a wrapper routine that
# can be called by SQLite and passes it the context, nargs, values
# and which gets the argument, then calls our routine, then puts
# the result back into the context.

# We have two options/approaches/
# One is to assume we are being given a double.
# The other is to be general and take whatever SQLite gives us and query its type.
# But we'll go with the first.
wrapper = function(ctxt, nargs, val) {
#              input = sqlite3_value_double(val[1])
#              ans = f(input)
#    printf("hi %lf %lf\n", input, ans)
       printf("hi %p \n", ctxt)
              sqlite3_result_double(ctxt, 2)
           }

# We have to declare the two sqlite3 routines. Basically these are pointers and we can
# treat them as being opaque types.

pType = pointerType(VoidType)

external = getBuiltInRoutines(sqlite3_value_double = list(DoubleType, pType),
                              sqlite3_result_double = list(VoidType, pType, DoubleType))
cwrapper = compileFunction(wrapper, VoidType, list(pType, Int32Type, pointerType(pType)),  module = as(cfun, "Module"),
                           .builtInRoutines = external, .readOnly = c("nargs", "val"))




ee = ExecutionEngine(cfun)
.llvm(cfun, 3, .ee = ee)
ptr = getPointerToFunction(cwrapper, ee)


db = dbConnect(SQLite(), "dataexpo")

sqliteExtension(db, getLoadedDLLs()[["RSQLiteUDF"]][["path"]])
initExtension(db)


createSQLFunction(db, ptr@ref, "foo", nargs = 1L)
d = dbGetQuery(db, "SELECT surftemp, foo(surftemp) FROM measure_table WHERE surftemp = 314.9")
