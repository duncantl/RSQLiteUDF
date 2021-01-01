library(RSQLite)
library(RSQLiteUDF)

library(Rllvm)
sir = parseIR("sqle.ir")

if(TRUE) {
# Load the fib routine and test.
mod = parseIR(system.file("IR", "fib.ll", package = "Rllvm"))
#.llvm(mod$fib, 10)
sir$fib = mod$fib

#newFib = Function("fib", Int32Type, list(Int32Type), module = sir)
#.Call("R_CloneFunctionInto", mod$fib, newFib, TRUE) # FALSE may be appropriate.  Have to handle recursive references to fib
} else {
#XXX Will copy fib here later. For now create function that returns 10L always.
fib = simpleFunction("fib", Int32Type, n = Int32Type, mod = sir)
fib$ir$createReturn(fib$ir$createConstant(10L))
}


# This is the pseudo-codde for the wrapper we want to create
if(FALSE) {
sqlFib =
function(ctxt, nargs, val)
{
   i = sqlite3_value_int(val)
   ans = fib(i)
   sqlite3_result_int(ctxt, ans)
}
}

# How to build this routine.
# We need type information from sqlite3ext.h. So we read it via IR
# by first generating the IR from sqle.c.  This is the same for any UDF.

ty = Rllvm::getType(sir[["sqlite3_api"]])
struct = getElementType(getElementType(ty))
fields = getFields(struct)
fieldNames = lapplyDebugInfoTypes(sir, function(x) names(getElements(x)))
w = sapply(fieldNames, is.character)  
names(fields) = fieldNames[w][[ "sqlite3_api_routines" ]]
offsets = structure(seq(along = fields) - 1L, names = names(fields))


vptrType = pointerType(VoidType)

# Want to specify the type sqlite3_value ** for val parameter.
# It is opaque. We can create that ourselves, but how do we get it from the IR by type name.

sqlite3_value_p = getParameters(getElementType(fields$value_int))[[1]]
# check: getName(getElementType(sqlite3_value_p))
sqlite3_context_p = getParameters(getElementType(fields$result_int))[[1]]


#sfib = simpleFunction("sqlFib", VoidType, .types = list(ctxt = vptrType, nargs = Int32Type, val = pointerType(vptrType)), mod = sir)
sfib = simpleFunction("sqlFib", VoidType, .types = list(ctxt = sqlite3_context_p, nargs = Int32Type, val = pointerType(sqlite3_value_p)), mod = sir)

ir = sfib$ir

api = ir$createLoad(sir[["sqlite3_api"]])
gep = ir$createGEP(api, c(ir$createConstant(0L, Int64Type), offsets["value_int"]))
viFun = ir$createLoad(gep)
arg = ir$createLoad(sfib$params$val)
#arg = ir$createGEP(arg, c(0L))
#arg = sfib$params$val
#arg = ir$createLoad(arg)
i = ir$createCall(viFun, arg) # ir$createLoad(sfib$params$ctxt), arg)

ans = ir$createCall(sir$fib, i)


api = ir$createLoad(sir[["sqlite3_api"]])
gep = ir$createGEP(api, c(ir$createConstant(0L, Int64Type), offsets["result_int"]))
riFun = ir$createLoad(gep)
# Do we need to ensure the inbounds is on the GEP.
xx = ir$createCall(riFun, sfib$params$ctxt, ans)
ir$createReturn()



set =  Function("setSQLAPI2", VoidType, list(ptr = getElementType(getType(sir[["sqlite3_api"]]))), module = sir)
ir = IRBuilder(Block(set))
#v = ir$createLoad(getParameters(set)[[1]])
v = getParameters(set)[[1]]
ir$createStore(v, sir[["sqlite3_api"]])
ir$createReturn()

stopifnot(verifyModule(sir))

######################################################
if(TRUE) {
db = dbConnect(SQLite(), "fib.db")

sqliteExtension(db, getLoadedDLLs()[["RSQLiteUDF"]][["path"]])
initExtension(db)

ee = ExecutionEngine(sir)
ptr = getPointerToFunction(sir$sqlFib, ee)  

# We will generate our own version of setSQLAPI.
# Also can use sqlite3_api_routines as the type so it won't appear as char *.
# So may not need to create the CIF.
api = .Call("R_getSQLite3API")
#cif = Rffi::CIF(Rffi::voidType, list(Rffi::pointerType))
#.llvm(sir$setSQLAPI2, api, .ee = ee, .ffi = cif)
.llvm(sir$setSQLAPI2, api, .ee = ee)


createSQLFunction(db, ptr@ref, "fib", nargs = 1L)
d = dbGetQuery(db, "SELECT i, fib(i) from vals")


rtruth = sapply(d[,1], function(i) .llvm(sir$fib, i))
stopifnot(all(rtruth == d[,2]))
}





if(FALSE) {
# Test with the version we created in the C code.
ptr = getNativeSymbolInfo("sqlFib2")$address
createSQLFunction(db, ptr, "fib2", nargs = 1L)
d = dbGetQuery(db, "SELECT i, fib2(i) from vals")
}
