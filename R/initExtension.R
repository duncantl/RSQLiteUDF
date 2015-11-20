initExtension = sqliteExtension =
function(db, dll = getLoadedDLLs()[["RSQLite"]][["path"]])
{
    if (!db@loadable.extensions) 
        stop("Loadable extensions are not enabled for this db connection", call. = FALSE)

    dll = path.expand(dll)
    
    if(!file.exists(dll))
        stop("Cannot fild the extension file")
    
    dbGetQuery(db, sprintf("SELECT load_extension('%s')",  dll))
    
    TRUE
}