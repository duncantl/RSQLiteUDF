#include <sqlite3.h>
#include <sqlite3ext.h>

/* 

/usr/bin/clang -E sqle.c -o sqle.e -I/usr/local/include

/usr/bin/clang -g -S -emit-llvm sqle.c -o sqle.ir -I/usr/local/include
*/
SQLITE_EXTENSION_INIT1


#ifdef ADD_SET_API_R
void setSQLAPI(void *p)
{
    sqlite3_api = (sqlite3_api_routines *) p;
}
#endif
