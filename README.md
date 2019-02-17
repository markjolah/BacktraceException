<a href="https://travis-ci.org/markjolah/BacktraceException"><img src="https://travis-ci.org/markjolah/BacktraceException.svg?branch=master"/></a>
# BacktraceException

[BacktraceException](https://markjolah.github.io/BacktraceException/classbacktrace__exception_1_1BacktraceException.html) is a C++ exception type that produces a stack backtrace when thrown.  It
can capture this backtrace with several methods and the backtrace can be disabled.  The
goal is for the library to work on both Linux and windows 64-bit.

## Documentation
The BacktraceException Doxygen documentation can be build with the `OPT_DOC` CMake option and is also available on online:
  * [BacktraceException HTML Manual](https://markjolah.github.io/BacktraceException/index.html)
  * [BacktraceException PDF Manual](https://markjolah.github.io/BacktraceException/pdf/BacktraceException-0.2-reference.pdf)
  * [BacktraceException github repository](https://github.com/markjolah/BacktraceException)

## Background
Some exceptions are never meant to be thrown in the absence of programming or system error.  If on of these exceptions is thrown, it normally will be passed far up the stack before it is handled.  When debugging an application it can be useful to quickly identify where a critical exception is being thrown.  However,
once the high-level exception handler has received the critical exception, there may not sufficient information to determine exactly which part of the execution is producing the exception.

Clearly a debugger can be used to catch the exception as it is being thrown and eventually trace down the problem.  But, the process of opening up the debugger, setting catchpoints or breakpoints, restarting the application/computation, and waiting for the failure to reoccur is tedious, especially if the error occurs seconds, minutes, or hours after the program is started.  A full debugging session is often overkill as well.  A programmer actively debugging will often know exactly what the problem is immediately on inspection of the throwing line of code or upon a quick scan of the stack-backtrace.

With BacktraceException, there is no need to break out the debugger every time a critical exception escapes your numerical simulation or long-running application.  The BacktraceException object will capture a stack backtrace as it is being constructed, giving you a quick but very useful view of exactly what was happening when it all went south.

This works well in interactive environments like Python and Matlab when running compiled C++ numerical code.  Rather than getting a mysterious `NumericalError("Non finite")` exception message three hours into the computation with no further explanation, you now can get a stack backtrace.

## Features
 * Linux: Can use [glibc backtrace](https://www.gnu.org/software/libc/manual/html_node/Backtraces.html), fast efficient, moderately informative.
 * Linux: Can use [gdb backtraces](https://ftp.gnu.org/old-gnu/Manuals/gdb/html_node/gdb_42.html): much slower, but includes arguments and other info not present in glibc backtraces.
 * Windows: Currently cross-compiles but stack walker traces are not yet implemented.
 * Used [Glibc demangling](https://gcc.gnu.org/onlinedocs/libstdc++/manual/ext_demangling.html) for C++ symbols name
 * Easily installed as a standalone package or built alongside CMake or autotools projects.

## Using Backtrace Exception

A [BacktraceException](https://markjolah.github.io/BacktraceException/classbacktrace__exception_1_1BacktraceException.html) is used a a base class for application-defined
classes of critical errors that would not be recoverable, and a backtrace of the exception throwing site would be useful.

    struct UnrecoverableError : public BacktraceException {
        UnrecoverableError(std::string what) : BacktraceException("UnrecoverableError",what) {}
    };


 * Use `backtrace_exception::enable_backtraces()` or `backtrace_exception::disable_backtraces()` to control the generation of backtraces.  When disabled backtrace_exception behaves like a normal `std::exception`.
 * Build examples from the examples sub-directory with `OPT_EXAMPLES=1`
    $ ./build.debug.sh -DOPT_EXAMPLES=1
    $ ./_build/Debug/examples/backtrace_exception_example1

### Limitations
 * In order to get a backtrace, the exception must derive from `BacktraceException`.  Exceptions from third-party libraries or based on [`std::exception`](https://en.cppreference.com/w/cpp/error/exception) will not generate a backtrace.

### CMake configuration options

 * `BUILD_SHARED_LIBS` - Build shared libraries [Default: ON]
 * `BUILD_STATIC_LIBS` - Build static libraries [Default: ON]



