/** @file BacktraceException.cpp
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2017 - 2018
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief BacktraceException class member function definitions
 *
 */

#include "BacktraceException/BacktraceException.h"

#include <cstdlib>
#include <memory>
#include <iostream>
#include <string>
#include <sstream>
#include <vector>

#if defined(__linux__)
//Linux only includes
#include <unistd.h>
#include <cxxabi.h>
#include <sys/wait.h>
#include <execinfo.h>
#elif defined(_WIN32)
//Windows only includes
#include <windows.h>
#endif


namespace backtrace_exception {

#ifdef NDEBUG
static bool _backtraces_enabled = false;
#else
static bool _backtraces_enabled = true;
#endif



#if  defined(__linux__)
static BacktraceMethod _backtrace_method = BacktraceMethod::glibc;
#elif defined(_WIN32)
static BacktraceMethod _backtrace_method = BacktraceMethod::stackwalk;
#endif

BacktraceMethod get_backtrace_method()
{
    return _backtrace_method;
}

void set_backtrace_method(BacktraceMethod method)
{
#if defined(__linux__)
    switch(method) {
        case BacktraceMethod::glibc:
        case BacktraceMethod::gdb:
            _backtrace_method = method;
            return;
        default:
            throw std::invalid_argument("BacktraceException::set_backtrace_method() - Invalid backtrace method for linux.");
    }
#elif defined(_WIN32)
    switch(method) {
        case BacktraceMethod::stackwalk:
            _backtrace_method = method;
            return;
        default:
            throw std::invalid_argument("BacktraceException::set_backtrace_method() - Invalid backtrace method for WIN32.");
    }

#endif
}

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
    
    
#ifdef __linux__
namespace linux_debug {
    std::string demangle(std::string name)
    {
        int status = -4;
        std::unique_ptr<char, void(*)(void*)> res{abi::__cxa_demangle(name.c_str(), NULL, NULL, &status),std::free};
        return (status==0) ? res.get() : name;
    }

    std::string backtrace_glibc()
    {
        std::ostringstream bt;
        const size_t N=250;
        void *array[N];

        auto bt_size = backtrace(array, N);
        auto bt_names = backtrace_symbols(array, bt_size);
        auto orig_bt_names = bt_names;
        const ssize_t bt_num_remove_frames=3; //Number of internal call frames to remove.
        if(bt_size > bt_num_remove_frames) {
            //Remove first few frames which are internal to BacktraceException and not relevent for debugging Exceptions.
            bt_names += bt_num_remove_frames;
            bt_size -= bt_num_remove_frames;
        }
        std::vector<std::string> bt_strings(bt_names,bt_names+bt_size);
        free (orig_bt_names);

        for(auto &s:bt_strings) {
            auto p0 = s.find("(");
            if(p0>0) {
                auto p1 = s.rfind("+");
                if(p1>0) {
                    auto count = p1-p0-1;
                    auto name = demangle(s.substr(p0+1,count));
                    s.replace(p0+1,count,name);
                }
            }
        }

        bt<<"Obtained "<<bt_size<<" stack frames.\n";
        for(ssize_t i = 0; i < bt_size; i++) bt<<"["<<i<<"]: "<<bt_strings[i]<<"\n";
        return bt.str();
    }


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

    std::string backtrace_gdb()
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
            execlp("gdb", "gdb", "-q","--batch", "-n",
                          "-ex", "up 4",
                          "-ex", "info frame",
                          "-ex", "info threads",
                          "-ex", "thread apply all info stack",
                          name.c_str(), pid.c_str(), nullptr);
            abort(); /* If gdb failed to start */
        } else {
            //Parent
            close(out_pipe_write); //Not needed
            waitpid(child_pid,NULL,0);
            static const int BUF_SIZE=1024;
            char buf[BUF_SIZE];
            std::ostringstream os;
            ssize_t n_read = read(out_pipe_read,buf,BUF_SIZE);
            while(n_read != 0) {
                if(n_read>0) os.write(buf,n_read);
                n_read = read(out_pipe_read,buf,BUF_SIZE);
            }
            return os.str();
        }
    }

} /* namespace linux_debug */

#endif

BacktraceException::BacktraceException(std::string what) :
   _condition("unspecified"), _what(what), _backtrace(print_backtrace())
{ }

BacktraceException::BacktraceException(std::string condition, std::string what) :
   _condition(condition), _what(what), _backtrace(print_backtrace())
{ }

std::string BacktraceException::print_backtrace()
{
#ifdef __linux__
    if(!backtraces_enabled()) return "Backtraces temporarily disabled.";
    switch(_backtrace_method) {
        case BacktraceMethod::glibc:
            return linux_debug::backtrace_glibc();
        case BacktraceMethod::gdb:
            return linux_debug::backtrace_gdb();
        default:
            return "Backtrace method not implemented";
    }
#elif defined(_WIN32)
    return "Backtraces not implemented on WIN32";
#else
    return "Unknown system: Backtraces permanently disabled.";
#endif 
}
    
} /* namespace backtrace_exception */
