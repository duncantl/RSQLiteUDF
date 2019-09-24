# Overview

**Note this no longer works with the most recent version(s) of RSQLite, i.e., greater than 1.0.0
as this changed the C code storing the connection to the database. 
For now, we use RSQLite version 1.0.0.
In the future, we will make this work with subsequent versions of RSQLite.
The reason is that accessing the C-level pointer to the database was changed
in versions >  1.0.0 due to the use of Rcpp and I haven't had the time to chase 
down the numerous layers of C++ "smart" pointers.
This is a minor technical matter. The focus here is on the proof of concept
and the logistics to make it work.
**

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
