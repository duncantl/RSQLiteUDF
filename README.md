# Overview
We can perform SQL queries from R to the SQL engine and bring the results back to R.
We can then perform additional filtering and transformation on the results. 
It can be convenient and efficient to do more of the computations in the SQL engine
before bring the results back to R for post-processing.

SQL provides a limited set of functions for processing records during the SQL query.
It is useful to extend this set of functions so that more of the computation can be done in the
SQL query. These functions include scalar transformations (i.e., mapping a value to another value)
and aggregate functions.  (There are also trigger functions which are less important for our purposes.)

This package allows us to register both C routines and R functions to be used as SQL functions.
These include both scalar and aggregate functions.

This package goes beyond the RSQLite's initExtension() functionality as it allows us to register
C routines from arbitrary DLL/DSOs. More importantly, it allows us to use R functions as SQL functions.
This may be slow (although the package attempts to make them faster via some "obvious" tricks).
The ultimate goal is to be able to take R functions and compile them to machine code using 
the packages Rllvm and RLLVMCompile and other packages.