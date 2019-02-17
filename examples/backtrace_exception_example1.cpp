
#include<sstream>
#include<iostream>
#include<cmath>
#include<BacktraceException/BacktraceException.h>

using namespace backtrace_exception;

class UnrecoverableNumericalError : public BacktraceException
{
    public:
    UnrecoverableNumericalError(std::string what)
        : BacktraceException("Unrecoverable Numerical Error",what) { }
};

template<class FloatT>
FloatT compute_ratio(FloatT denominator)
{
    if(denominator==0.0) throw UnrecoverableNumericalError("denominator==0");
    return sqrt(2*denominator+denominator)/denominator;
}

void computation_1()
{
    compute_ratio<double>(0);
}

void foo()
{
    computation_1();
}

int tryit()
{
    try{
        foo();
    } catch(BacktraceException &e) {
        std::cout<<"Caught BacktraceException:\n\tCondition:"<<e.condition()<<"\n\twhat:"<<e.what()<<"\n\tbacktrace:\n"<<e.backtrace();
        return 0;
    }
    return -1;
}

int main()
{
    std::cout<<"===== Backtraces Disabled  =====\n";
    disable_backtraces();
    if(tryit()) return -1;
#if defined(__linux__)
    std::cout<<"\n===== BacktraceMethod::glibc  =====\n";
    enable_backtraces();
    set_backtrace_method(BacktraceMethod::glibc);
    if(tryit()) return -2;
    std::cout<<"\n===== BacktraceMethod::gdb  =====\n";
    enable_backtraces();
    set_backtrace_method(BacktraceMethod::gdb);
    if(tryit()) return -3;
#elif defined(_WIN32)
    std::cout<<"\n===== BacktraceMethod::stackwalk  =====\n";
    enable_backtraces();
    set_backtrace_method(BacktraceMethod::stackwalk);
    if(tryit()) return -4;
#endif
}
