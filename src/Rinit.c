#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#include <Rdefines.h>

void R_registerFunc(sqlite3_context*, int nargs, sqlite3_value **vals);
void myfloorFunc(sqlite3_context *context, int argc, sqlite3_value **argv);


int 
sqlite3_extension_init(sqlite3 *db,          /* The database connection */
                       char **pzErrMsg,      /* Write error messages here */
                       const sqlite3_api_routines *pApi  /* API methods */
                      )
{

    SQLITE_EXTENSION_INIT2(pApi);
    printf("In extension_init %p\n", db);
//    sqlite3_create_function(db, "registerFun", 2, SQLITE_UTF8, NULL, R_registerFunc, NULL, NULL);
    sqlite3_create_function(db, "ifloor", 1, SQLITE_UTF8, NULL, myfloorFunc, NULL, NULL);
    return(SQLITE_OK);
}


// From RSQLite's rsqlite.h
typedef struct SQLiteConnection {
  sqlite3* drvConnection;  
  void  *resultSet;
    // RSQLiteException *exception;
} SQLiteConnection;

sqlite3 *
GET_SQLITE_DB(SEXP rdb)
{
    SQLiteConnection * con = (SQLiteConnection *) R_ExternalPtrAddr(rdb);
    return(con->drvConnection);
}

SEXP
R_enable_load_extension(SEXP rdb, SEXP on)
{
    int status;
    sqlite3 *db;
    db = GET_SQLITE_DB(rdb);
    status = sqlite3_enable_load_extension(db, LOGICAL(on)[0]);
    return(ScalarInteger(status));
}



void 
R_registerFunc(sqlite3_context *ctxt, int nargs, sqlite3_value **vals)
{
//    sqlite3_create_function(db, "ifloor", 1, SQLITE_UTF8, NULL, floorFunc, NULL, NULL);
}


SEXP
makeRArgument(sqlite3_value *val)
{
    SEXP ans = R_NilValue;

    switch(sqlite3_value_type(val)) {
       case SQLITE_INTEGER: {
           int iVal = sqlite3_value_int(val);
	   ans = ScalarInteger(iVal);
	   break;
       }
       case SQLITE_FLOAT: {
	   ans = ScalarReal(sqlite3_value_double(val));
	   break;
       }

       case SQLITE_TEXT:
	   ans = ScalarString(mkChar((char *) sqlite3_value_text(val)));
	   break;

       default:
	   PROBLEM "Unhandled conversion of argument UDF from SQLite to R"
	       WARN;
	   break;
    }
    return(ans);
}


int
convertRResult(SEXP ans, sqlite3_context *context)
{
    switch(TYPEOF(ans)) {
      case INTSXP:
	  sqlite3_result_int(context, INTEGER(ans)[0]);
	  break;
      case REALSXP:
	  sqlite3_result_double(context, REAL(ans)[0]);
	  break;

      case STRSXP: {
	  char *str = CHAR(STRING_ELT(ans, 0));
	  sqlite3_result_text(context, str, -1, SQLITE_TRANSIENT);
	  break;
      }
// Add more
    default:
	   PROBLEM "Unhandled conversion of result of UDF from R to SQLite"
	       WARN;
	   break;
    }

    return(0);
}



typedef void (*SQLiteFunc)(sqlite3_context*,int,sqlite3_value**);

void
R_doCall(sqlite3_context *ctxt, int nargs, sqlite3_value **vals, SEXP e)
{
    SEXP ans, cur, val;
    int err = 0;
          
    cur = CDR(e);
    for(int i = 0; i < nargs; i++) {
	val = makeRArgument(vals[i]);
	SETCAR(cur, val);
	cur = CDR(cur);
    }
    ans = Rf_eval(e, R_GlobalEnv); //, &err);
    PROTECT(ans);
    convertRResult(ans, ctxt);
    UNPROTECT(1);
}


void
R_callFunc(sqlite3_context *ctxt, int nargs,sqlite3_value** vals)
{
    SEXP e = (SEXP) sqlite3_user_data(ctxt);
    R_doCall(ctxt, nargs, vals, e);
}


void
R_mkCallFunc(sqlite3_context *ctxt, int nargs,sqlite3_value** vals)
{
    SEXP r_func = (SEXP) sqlite3_user_data(ctxt);
    SEXP expr;
    
    PROTECT(expr = allocVector(LANGSXP, nargs + 1));
    SETCAR(expr, r_func);
    R_doCall(ctxt, nargs, vals, expr);    
    UNPROTECT(1);
}

void
Rsqlite_Release(void *val)
{
    R_ReleaseObject((SEXP) val);
}

SEXP
R_registerSQLFunc(SEXP rdb, SEXP r_func, SEXP rname, SEXP rnargs)
{
    sqlite3 *db = GET_SQLITE_DB(rdb);
    void *udata = NULL;
    SQLiteFunc fun;
    int nargs = INTEGER(rnargs)[0];

    if(TYPEOF(r_func) == EXTPTRSXP) {
	fun = (SQLiteFunc) R_ExternalPtrAddr(r_func);
	sqlite3_create_function(db, CHAR(STRING_ELT(rname, 0)), nargs, SQLITE_UTF8, udata, fun, NULL, NULL);
    } else {
	SEXP expr;
	if(nargs > -1) {
	    expr = allocVector(LANGSXP, nargs + 1);
	    R_PreserveObject(expr);
	    SETCAR(expr, r_func);
	    udata = expr;
	    fun = R_callFunc;
	} else {
	    R_PreserveObject(r_func);
	    udata = r_func;
	    fun = R_mkCallFunc;
	}
	sqlite3_create_function_v2(db, CHAR(STRING_ELT(rname, 0)), nargs, SQLITE_UTF8, udata, fun, NULL, NULL, Rsqlite_Release);
    }

    return(R_NilValue); // return a ticket to be able to release the fun.
}


/*
Borrowed from the RSQLite package's code, and originally from Liam Healy.

 */

#include <math.h>
#include <stdint.h>

typedef uint8_t         u8;
typedef uint16_t        u16;
typedef int64_t         i64;

/*
** largest integer value not greater than argument
*/
void myfloorFunc(sqlite3_context *context, int argc, sqlite3_value **argv){
  double rVal=0.0;

  switch( sqlite3_value_type(argv[0]) ){
    case SQLITE_INTEGER: {
      i64 iVal = sqlite3_value_int64(argv[0]);
      sqlite3_result_int64(context, iVal);
      break;
    }
    case SQLITE_NULL: {
      sqlite3_result_null(context);
      break;
    }
    default: {
      rVal = sqlite3_value_double(argv[0]);
      sqlite3_result_int64(context, (i64) floor(rVal));
      break;
    }
  }
}
