\name{createSQLFunction}
\alias{createSQLFunction}
\alias{createSQLAggregateFunction}
\title{Register an R function or C routine as an SQL Function}
\description{
  These functions allow us to register R functions or C routines
  with an SQLite database so that the functions can be used directly
  within SQL queries as scalar and aggregate functions.
  This allows us to augment the functionality within SQL directly with R
  functions, or by C code in different DLLs/DSOs (compiled libraries).
  We can register scalar functions that return a value for each record
  on which they are called (e.g., log), and also aggregate functions that process
  multiple records and finally return a single result (e.g. average).
}
\usage{
createSQLFunction(db, func, name = substitute(func), nargs = -1L, isRoutine = FALSE, userData = NULL)
createSQLAggregateFunction(db, step, final, name = substitute(step), nargs = -1L, 
                            isRoutine = FALSE, userData = NULL) 
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{db}{the database in which the function is being registered}
  \item{func}{the scalar function or routine being registered.
   This can be specified as an R function, or as the address of a C
   routine, or as a description of a C routine obtained by
   \code{getNativeSymbolInfo}.
   The caller can also specify a character string to specify the name
   of a C routine. This is less desirable than calling
   \code{getNativeSymbolInfo} as there is ambiguity as to how this is found and resolved.
 }
  \item{step}{part of an aggregate function. This is the per-record R
    function that is called for each record.
   }
  \item{final}{this is the final step in an aggregate function. This is
    the R function that is called to compute the final result having
    processed all the records in the \code{step} function.}
  \item{name}{the name by which this function can be called in SQL}
  \item{nargs}{the number of arguments that should be specified in each
    call to this function. If this is -1, the function can be called
    with different numbers of arguments, i.e., it is variadic.}
  \item{isRoutine}{a logical value, with \code{TRUE} indicating that
    \code{func} is to be interpreted as a compiled routine.
    This then interprets \code{func} as the name of the routine
    and uses \code{getNativeSymbolInfo} to find this routine.
   }
   \item{userData}{data that is passed to the C routines each time they
     are called.  This is typically an \code{externalptr} object referencing
     a native data structure. }
}
%\details{}
\value{
These functions are used for their side effects of registering
the functions to be used in SQL queries.
}
%\references{}
\author{
Duncan Temple Lang
}
\seealso{
\code{\link{sqliteExtension}}
\code{\link[DBI]{dbGetQuery}}
}
\examples{
library(RSQLite)

db = dbConnect(SQLite(), ":memory:")

ptr = getNativeSymbolInfo("myfloorFunc")$address
createSQLFunction(db, ptr, "myfloor", 1L)
dbGetQuery(db, "SELECT myfloor(2.3);")


createSQLFunction(db, nchar, "numChars", 1L)
dbGetQuery(db, "SELECT numChars('bob');")
dbGetQuery(db, "SELECT numChars('Robert');")
}
\keyword{IO}
