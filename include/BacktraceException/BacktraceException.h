/** @file BacktraceException.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2017 - 2018
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief BacktraceException class declaration and inline member functions
 *
 */

#pragma once

#include <exception>
#include <string>

namespace backtrace_exception {

void disable_backtraces();
void enable_backtraces();
bool backtraces_enabled();
    
/** @brief Extension of std::exception that produces saved backtraces for debugging
 * 
 * 
 */
class BacktraceException : public std::exception
{
public:
    BacktraceException(std::string what);

    /** @brief Create a BacktraceException with specified condition
    * 
    * @param condition A string further classifying the error condition 
    * @param what A general string describing the error condition.
    */
    BacktraceException(std::string condition, std::string what);
    virtual const char* condition() const noexcept;
    const char* what() const noexcept override;
    virtual const char* backtrace() const noexcept;
    static std::string print_backtrace(); 
protected:
    std::string _condition;
    std::string _what;
    std::string _backtrace;
};

inline
const char* BacktraceException::condition() const noexcept
{ return _condition.c_str(); }

inline
const char* BacktraceException::what() const noexcept
{ return _what.c_str(); }

inline
const char* BacktraceException::backtrace() const noexcept
{ return _backtrace.c_str(); }

    
} /* namespace backtrace_exception */
