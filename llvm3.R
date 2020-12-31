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

# These are declarations, but this code (llvm3.R) assumes they are real routines that are implemented
# as opposed to function pointers we get from the sqlite3_api instance. See llvmAddSymbol below.
sql_get_int = Function("mysqlite3_value_int2", Int32Type, list(vptrType), module = sfib$module)
sql_ret_int = Function("mysqlite3_result_int", VoidType, list(vptrType, Int32Type), module = sfib$module)


#arg = ir$createLoad(sfib$params$val)
arg = sfib$params$val
#arg = ir$createGEP(arg, c(0L))
arg = ir$createLoad(arg)
i = ir$createCall(sql_get_int, arg)
ans = ir$createCall(mod$fib, i)
ir$createCall(sql_ret_int, sfib$params$ctxt, ans)
ir$createReturn()


# Now ready to call this routine.

r = c("mysqlite3_value_int2", "mysqlite3_result_int")
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
#d = dbGetQuery(db, "SELECT i, fib(i) from vals")





if(FALSE) {
# Test with the version we created in the C code.
ptr = getNativeSymbolInfo("sqlFib2")$address
createSQLFunction(db, ptr, "fib2", nargs = 1L)
d = dbGetQuery(db, "SELECT i, fib2(i) from vals")
}
