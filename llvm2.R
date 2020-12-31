library(RSQLite)
library(RSQLiteUDF)


library(Rllvm)
mod = parseIR(system.file("IR", "fib.ll", package = "Rllvm"))
.llvm(mod$fib, 10)

if(FALSE) {
wrapper =
function(ctxt, nargs, val)
{
   i = sqlite3_value_int(val)
   ans = fib(i)
   sqlite3_result_int(ctxt, ans)
}
}

vptrType = pointerType(VoidType)

sfib = simpleFunction("sqlFib", Int32Type, .types = list(ctxt = vptrType, nargs = Int32Type, val = pointerType(vptrType)), mod = mod)
ir = sfib$ir
##X sql_get_int = Function("mysqlite3_value_int", Int32Type, list(vptrType), module = sfib$module)
sql_get_int = Function("mysqlite3_value_int2", Int32Type, list(vptrType), module = sfib$module)
sql_ret_int = Function("mysqlite3_result_int", VoidType, list(vptrType, Int32Type), module = sfib$module)


# This segfaults.  We are assuming there is a routine sqlite3_value_int
# yet in the header files and in the ir we generate from Rinit.c,
# we see accessing the sqlite3_api object and getting the corresponding element
# as a function pointer and calling that.

#arg = ir$createLoad(sfib$params$val)
arg = sfib$params$val
#X
arg = ir$createGEP(arg, c(0L))
arg = ir$createLoad(arg)
i = ir$createCall(sql_get_int, arg)
ans = ir$createCall(mod$fib, i)
ir$createCall(sql_ret_int, sfib$params$ctxt, ans)
ir$createReturn()


r = c("mysqlite3_value_int", "mysqlite3_result_int", "mysqlite3_value_int2")
invisible(lapply(r, function(r)
                       llvmAddSymbol(getNativeSymbolInfo(r) )))

ee = ExecutionEngine(mod)

ptr = getPointerToFunction(mod$sqlFib, ee)  # sfib$fun


db = dbConnect(SQLite(), "fib.db")
d = dbGetQuery(db, "SELECT i from vals")

sqliteExtension(db, getLoadedDLLs()[["RSQLiteUDF"]][["path"]])
initExtension(db)

d = dbGetQuery(db, "SELECT i from vals")

createSQLFunction(db, ptr@ref, "fib", nargs = 1L)
# d = dbGetQuery(db, "SELECT i, fib(i) from vals")



# Test with the version we created in the C code.
if(FALSE) {
ptr = getNativeSymbolInfo("sqlFib2")$address
createSQLFunction(db, ptr, "fib2", nargs = 1L)
d = dbGetQuery(db, "SELECT fib2(i) from vals")
}
