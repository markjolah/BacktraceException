/** @file BacktraceException.cpp
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2017 - 2018
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief BacktraceException class member function definitions
 *
 */

#include "BacktraceException/BacktraceException.h"

#include <iostream>
#include <string>
#include <sstream>
#include <vector>

#if !defined(WIN32)
//Linux only includes
#include <unistd.h>
#include <sys/wait.h>
#else
//Windows only includes

#endif


namespace backtrace_exception {

#ifdef NDEBUG
static bool _backtraces_enabled = false;
#else
static bool _backtraces_enabled = true;
#endif
    
void disable_backtraces()
{
    _backtraces_enabled = false;
}

void enable_backtraces()
{
    _backtraces_enabled = true;
}

bool backtraces_enabled()
{    
    return _backtraces_enabled;
}
    
    
#if defined(__linux__)
namespace linux_debug {
    std::string get_exename()
    {
        ssize_t sz=512;
        do {
            std::vector<char> buf(sz);
            ssize_t len = readlink("/proc/self/exe", buf.data(), buf.size());
            if (len<0) return ""; //Error reading
            if (len<sz) {
                buf[len]=0; //Null terminate
                return buf.data();
            }
            sz*=2;    
        } while ( sz>0 );
        return ""; //Too big to handle.  Should never get here.
    }

    //TODO use backtrace()
    //Reference: https://sourceware.org/git/?p=glibc.git;a=blob;f=debug/segfault.c;hb=HEAD
//     std::string print_trace_backtrace()
//     {
//     }
//
    std::string print_trace_gdb() 
    {
        auto pid = std::to_string(getpid());
        auto name = get_exename();
        int out_pipe[2];
        int& out_pipe_read = out_pipe[0];
        int& out_pipe_write = out_pipe[1];
        if( ::pipe(out_pipe) ) return "[Bad Pipe]";
            
        int child_pid = ::fork();
        if (!child_pid) {
            //Child
            dup2(out_pipe_write,1); // redirect stdout to out_pipe
            dup2(out_pipe_write,2); // redirect stderr to out_pipe
            close(out_pipe_read); //For parent
            close(out_pipe_write); //For parent
            std::cout<<"Stack trace for exename="<<name<<" pid="<<pid<<std::endl;
            execlp("gdb", "gdb", "--batch", "-n", 
                          "-ex", "info threads",
                          "-ex", "thread apply all info stack full", 
                          name.c_str(), pid.c_str(), nullptr);
            abort(); /* If gdb failed to start */
        } else {
            //Parent
            close(out_pipe_write); //Not needed
            waitpid(child_pid,NULL,0);
            static const int BUF_SIZE=1024;
            char buf[BUF_SIZE];
            ssize_t n_read = read(out_pipe,buf,BUF_SIZE,0);
            std::ostringstream os;
            while(n_read != 0) {
                if(n_read>0) os.write(buf,n_read);
            }
            return os.str();
        }
    }

} /* namespace linux_debug */

#endif


BacktraceException::BacktraceException(std::string condition, std::string what) :
   _condition(condition), _what(what), _backtrace(print_backtrace())
{ }

std::string BacktraceException::print_backtrace()
{
#if defined (LINUX)
    if(!backtraces_enabled()) return "Backtraces temporarily disabled.";
    return linux_debug::print_trace_gdb();
#elif defined(WIN32)
    return "Backtraces not implemented.";
#else
    return "Backtraces permanently disabled.";
#endif 
}
    
} /* namespace backtrace_exception */
