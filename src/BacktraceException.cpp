/** @file BacktraceException.cpp
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2017
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief BacktraceException class member function definitions
 *
 */

#include "BacktraceException.h"
#include <iostream>
#include <string>
#include <sstream>
#include <vector>
#include <boost/iostreams/device/file_descriptor.hpp>
#include <boost/iostreams/stream_buffer.hpp>

#if !defined(WIN32)
//Linux only includes
#include <unistd.h>
#include <sys/wait.h>
#else
//Windows only includes

#endif

namespace io = boost::iostreams; //Namespace alias

namespace backtrace_exception {

static bool _backtraces_enabled = true;
    
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
    
    
#if !defined(WIN32)
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

            io::file_descriptor_source source(out_pipe_read, boost::iostreams::close_handle);
            io::stream_buffer<io::file_descriptor_source> pipe_stream_buf(source);
            std::ostringstream os;
            os<<&pipe_stream_buf;
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
    if(!backtraces_enabled()) return "Backtraces currently disabled";
    
#if defined (DEBUG) && !defined (WIN32)    
//Linux -rdynamic symbols available.  Make as pretty as possible
    return linux_debug::print_trace_gdb();
#elif defined(LINUX) && !defined (WIN32)
//Linux no -rdynamic symbols available
    return linux_debug::print_trace_gdb();    
#elif defined (DEBUG) && defined (WIN32)
//Windows debug
    return "WIN32 Backtrace Not Implemented";
#elif defined (WIN32)
//Windows
    return "WIN32 Backtrace Not Implemented";
#endif 
}


    
} /* namespace backtrace_exception */
