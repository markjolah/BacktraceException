
#include<sstream>
#include<iostream>
#include<BacktraceException/BacktraceException.h>

using namespace backtrace_exception;

template<class T>
void baz(T)
{
    throw BacktraceException("BazBorked","Baz is done.");
}

void bar()
{
    baz<int>(0);
}

void foo()
{
    bar();
}

int tryit()
{
    try{
        foo();
    } catch(BacktraceException &e) {
        std::cout<<"Caught BacktraceException:\n\tCondition:"<<e.condition()<<"\n\tmessage:"<<e.message()<<"\n\tbacktrace:\n"<<e.backtrace();
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
