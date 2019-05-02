/** @file BacktraceException.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2017 - 2019
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief BacktraceException class declaration and inline member functions
 *
 */

#pragma once

#include <exception>
#include <string>

namespace backtrace_exception {

enum class BacktraceMethod { glibc, gdb, stackwalk };

void disable_backtraces();
void enable_backtraces();
bool backtraces_enabled();
BacktraceMethod get_backtrace_method();
void set_backtrace_method(BacktraceMethod method);

/** @brief Extension of std::exception that produces saved backtraces for debugging
 * 
 * 
 */
class BacktraceException : public std::exception
{
public:
    BacktraceException(std::string message);

    /** @brief Create a BacktraceException with specified condition
    * 
    * @param condition A string classifying the error condition
    * @param message A message string describing the error condition.
    */
    BacktraceException(std::string condition, std::string message);
    virtual const char* condition() const noexcept;
    virtual const char* message() const noexcept;
    virtual const char* backtrace() const noexcept;
    const char* what() const noexcept override;
    static std::string print_backtrace(); 
protected:
    std::string _condition;
    std::string _message;
    std::string _backtrace;
};

inline
const char* BacktraceException::condition() const noexcept
{ return _condition.c_str(); }

inline
const char* BacktraceException::message() const noexcept
{ return _message.c_str(); }

inline
const char* BacktraceException::backtrace() const noexcept
{ return _backtrace.c_str(); }



} /* namespace backtrace_exception */
