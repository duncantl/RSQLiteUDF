\name{sqliteExtension}
\alias{sqliteExtension}
\alias{initExtension}
\title{Load an SQLite extension into an SQL database}
\description{
  This function is a generalization of initExtension in the RSQLite
  package.
  This allows us to load extensions from different compiled DLLs/DSOs.
}
\usage{
sqliteExtension(db, dll = getLoadedDLLs()[[pkg]][["path"]], pkg = "RSQLite")
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{db}{the SQLite database connection into which the extension will
  be loaded. The extension needs to be loaded for each new database.}
  \item{dll}{the full path the DLL containing the compiled code.}
  \item{pkg}{the name of an R package whose compiled code contains the
    extension code. This is a more convenient way to locate the DLL/DSO.}
}
\value{
This function is used for its side effect.
}
\references{
\url{https://www.sqlite.org/loadext.html}  
}
\author{
  Duncan Temple Lang, adapted from \code{initExtension}
  in RSQLite.
}

\examples{
library(RSQLite)
db = dbConnect(SQLite(), ":memory:")
sqliteExtension(db, pkg = "RSQLite")
sqliteExtension(db, pkg = "RSQLiteUDF")
}
\keyword{IO}
