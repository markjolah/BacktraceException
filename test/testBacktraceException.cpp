
#include<sstream>
#include<iostream>
#include<BacktraceException/BacktraceException.h>

using namespace backtrace_exception;

void baz()
{
    throw BacktraceException("Baz is done.");
}

void bar()
{
    baz();
}

void foo()
{
    bar();
}


int main()
{
    try{
        foo();
    } catch(BacktraceException &e) {
//         std::ostringstream msg;
        std::cout<<"Caught BacktraceException:\n\tCondition:"<<e.condition()<<"\n\twhat:"<<e.what()<<"\n\tbacktrace:\n"<<e.backtrace();

        return 0;
    }
    return -1; //Should have caught
}
