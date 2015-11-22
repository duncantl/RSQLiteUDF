
createSQLFunction =
function(db, func, nargs = -1L, name = substitute(func), isRoutine = is.character(func), userData = NULL)
{
  sqliteExtension(db, pkg = "RSQLiteUDF")
  name # force
  
  if(is.character(func) && isRoutine)
     func = getNativeSymbolInfo(func)$address

  if(inherits(func, "NativeSymbolInfo")  )
      func = func$address

  if(nargs < 0)
      nargs = sum(!sapply(formals(func), hasDefaultValue))
      
  
  .Call("R_registerSQLFunc", db@Id, func, as.character(name), as.integer(nargs), userData)
}

hasDefaultValue =
function(param)
{
   !(is.name(param) && param == "")
}



createSQLAggregateFunction =
function(db, step, final, nargs = -1L, name = substitute(step), isRoutine = FALSE, userData = NULL)
{
  sqliteExtension(db, pkg = "RSQLiteUDF")
  
  if(is.character(step) && isRoutine) 
     step = getNativeSymbolInfo(step)$address
  
  if(is.character(final) && isRoutine) 
     final = getNativeSymbolInfo(final)$address

  if(inherits(step, "NativeSymbolInfo")  )
      step = step$address
  
  if(inherits(final, "NativeSymbolInfo")  )
      final = final$address  

  if(nargs < 0)
      nargs = sum(!sapply(formals(step), hasDefaultValue))
  
  .Call("R_registerSQLAggregateFunc", db@Id, step, final, as.character(name), as.integer(nargs), userData)
}
