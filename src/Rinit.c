#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#include <Rdefines.h>
#include <stdlib.h>

void R_registerFunc(sqlite3_context*, int nargs, sqlite3_value **vals);
void myfloorFunc(sqlite3_context *context, int argc, sqlite3_value **argv);


int 
sqlite3_extension_init(sqlite3 *db,          /* The database connection */
                       char **pzErrMsg,      /* Write error messages here */
                       const sqlite3_api_routines *pApi  /* API methods */
                      )
{

    SQLITE_EXTENSION_INIT2(pApi);
#if 0
Rprintf("in sqlite3_extension_init for RSQLiteUDF sqlite3_api = %p\n", sqlite3_api);
Rprintf("value_int = %p\n", sqlite3_api->value_int); 
#endif
//    sqlite3_create_function(db, "registerFun", 2, SQLITE_UTF8, NULL, R_registerFunc, NULL, NULL);
//    sqlite3_create_function(db, "ifloor", 1, SQLITE_UTF8, NULL, myfloorFunc, NULL, NULL);
    return(SQLITE_OK);
}


#if OLD
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

#else
sqlite3 *
GET_SQLITE_DB(SEXP rdb)
{
    conn()
}
#endif

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
	  const char *str = CHAR(STRING_ELT(ans, 0));
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
typedef void (*SQLiteFinalFunc)(sqlite3_context *);


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
    ans = R_tryEval(e, R_GlobalEnv, &err);
    if(err == 0) {
	PROTECT(ans);
	convertRResult(ans, ctxt);
	UNPROTECT(1);
    }
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
R_registerSQLFunc(SEXP rdb, SEXP r_func, SEXP rname, SEXP rnargs, SEXP userData)
{
    sqlite3 *db = GET_SQLITE_DB(rdb);
    void *udata = NULL;
    SQLiteFunc fun;
    int nargs = INTEGER(rnargs)[0];

    if(TYPEOF(r_func) == EXTPTRSXP) {
	fun = (SQLiteFunc) R_ExternalPtrAddr(r_func);
	if(Rf_length(userData))
	    udata = R_ExternalPtrAddr(userData);
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


void
Rsqlite_ReleaseAggregate(void *ptr)
{
    SEXP *arr = (SEXP *) ptr;
    R_ReleaseObject(arr[0]);
    R_ReleaseObject(arr[1]);
    free(ptr);
}


void
R_callAggregateFunc(sqlite3_context *ctxt, int nargs,sqlite3_value** vals)
{
     SEXP *expressions = (SEXP *) sqlite3_user_data(ctxt);
     R_doCall(ctxt, nargs, vals, expressions[0]);     
}

void
R_callFinalFunc(sqlite3_context *ctxt)
{
     SEXP *expressions = (SEXP *) sqlite3_user_data(ctxt);
     SEXP ans = Rf_eval(expressions[1], R_GlobalEnv);
     convertRResult(ans, ctxt);
}

void
R_mkAggregateCallFunc(sqlite3_context *ctxt, int nargs,sqlite3_value** vals)
{
     SEXP *expressions = (SEXP *) sqlite3_user_data(ctxt);
     R_doCall(ctxt, nargs, vals, expressions[0]);    
}



SEXP
R_registerSQLAggregateFunc(SEXP rdb, SEXP r_stepFunc, SEXP r_finalFunc, SEXP rname, SEXP rnargs, SEXP ruserData)
{
    sqlite3 *db = GET_SQLITE_DB(rdb);
    void *udata = NULL;
    SQLiteFunc stepFun;
    SQLiteFinalFunc finalFun;
    int nargs = INTEGER(rnargs)[0];

    if(TYPEOF(r_stepFunc) == EXTPTRSXP) {
	stepFun = (SQLiteFunc) R_ExternalPtrAddr(r_stepFunc);
	finalFun = (SQLiteFinalFunc) R_ExternalPtrAddr(r_finalFunc);
	if(TYPEOF(ruserData) == EXTPTRSXP)
	    udata = R_ExternalPtrAddr(ruserData);

	sqlite3_create_function(db, CHAR(STRING_ELT(rname, 0)), nargs, SQLITE_UTF8, udata, NULL, stepFun, finalFun);

    } else {
	SEXP expr;
	SEXP *funs = (SEXP *) malloc(sizeof(SEXP) * 2);
	udata = funs;

	funs[1] = expr = allocVector(LANGSXP, 1);
	R_PreserveObject(expr);
	SETCAR(expr, r_finalFunc);	    
	finalFun = R_callFinalFunc;

	if(nargs > -1) {
	    funs[0] = expr = allocVector(LANGSXP, nargs + 1);
	    R_PreserveObject(expr);
	    SETCAR(expr, r_stepFunc);
	    
	    stepFun = R_callAggregateFunc;
	} else {
	    R_PreserveObject(r_stepFunc);
	    funs[0] = r_stepFunc;
	    stepFun = R_mkAggregateCallFunc;
	}
	sqlite3_create_function_v2(db, CHAR(STRING_ELT(rname, 0)), nargs, SQLITE_UTF8, udata, NULL, stepFun, finalFun, Rsqlite_ReleaseAggregate);
    }

    return(R_NilValue); // return a ticket to be able to release the fun.
}


#define MIN(a, b) ((a) < (b) ? (a) : (b))

/*
  Get the last n characters from a string
 This is motivated by pulling the year from the end of a string such as
   USA:22 September 1986 
 to get 1986
 */
void 
lastNChars(sqlite3_context *context, int argc, sqlite3_value **argv)
{
    const char * str;
    const char *ptr;
    str = sqlite3_value_text(argv[0]);
    int n = sqlite3_value_int(argv[1]);
    int len = strlen(str);
    if(n > 0) {
        n = MIN(len, n);
	ptr = str +  len - n ;
	sqlite3_result_text(context, ptr, -1, SQLITE_TRANSIENT);
    }
}




/*
Borrowed from the RSQLite package's code, and originally from Liam Healy.
See https://www.sqlite.org/contrib
*/

#include <math.h>
#include <stdint.h>

typedef uint8_t         u8;
typedef uint16_t        u16;
typedef int64_t         i64;

/*
** largest integer value not greater than argument
*/
void myfloorFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  double rVal=0.0;

  switch( sqlite3_value_type( argv[0] ) ){
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



int
fib2(int n)
{
    if(n < 2)
	return(n);
    
    return(fib2(n-1) + fib2(n-2));
}

void
sqlFib2(sqlite3_context *context, int argc, sqlite3_value **argv)
{
   int type = sqlite3_value_type(argv[0]);
   fprintf(stderr, "data type in sqlFib2 %d\n", type);fflush(stderr);
   int arg = sqlite3_value_int(argv[0]);
   int ans = fib2(arg);
   sqlite3_result_int(context, ans);
}



SEXP
R_getSQLite3API()
{
  return(R_MakeExternalPtr((void *) sqlite3_api, Rf_install("sqlite3a_api"), R_NilValue));
}
