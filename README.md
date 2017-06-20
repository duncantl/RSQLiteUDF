# Overview

**Note this no longer works with the most recent version(s) of RSQLite, i.e., greater than 1.0.0
as this changed the C code storing the connection to the database. It is possible to modify this
package to access the C structure we need. However, it is wrapped within numerous layers of C++ 
smart pointers**

The RSQLite package allows us to perform SQL queries from R to the SQL engine and bring the results back to R.
We can then perform additional filtering and transformation on the results. 
However, it can be convenient and efficient to do more of the computations in the SQL engine
before bringing the results back to R for post-processing.

SQL provides a somewhat limited set of functions for processing records during the SQL query.
It is useful to extend this set of functions so that more of the computations can be done in the
SQL query. Generally, these functions include scalar transformations (i.e., mapping a value to another value)
and aggregate functions.  (There are also trigger functions which are less important for our purposes.)

This package allows us to register both C routines and R functions to be used as SQL functions.
These include both scalar and aggregate functions.

This package goes beyond the RSQLite's initExtension() functionality
as it allows us to register C routines from arbitrary DLL/DSOs. More
importantly, it allows us to use R functions as SQL functions.  This
may be slow (although the package attempts to make them faster via
some "obvious" tricks).  The ultimate goal, however, is to be able to
take R functions and compile them to machine code using the packages
Rllvm and RLLVMCompile and other packages.  With an embedded SQL
engine, this is very feasible now.
