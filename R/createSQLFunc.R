
createSQLFunction =
function(db, func, name = substitute(func), nargs = -1L, isRoutine = FALSE)
{
  if(is.character(func) && isRoutine)
     func = getNativeSymbolInfo(func)$address

  if(nargs < 0)
      nargs = sum(!sapply(formals(func), hasDefaultValue))
      
  
  .Call("R_registerSQLFunc", db@Id, func, as.character(name), as.integer(nargs))
}

hasDefaultValue =
function(param)
{
   !(is.name(param) && param == "")
}


