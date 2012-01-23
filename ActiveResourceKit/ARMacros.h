// ActiveResourceKit ARMacros.h
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

/*!
 * @param array A standard C array of fixed-sized elements.
 * @brief Answers the number of elements in the given array, the array's dimension.
 * @details Assumes that the array argument is a standard C-style array where
 * the compiler can assess the number of elements by dividing the size of the
 * entire array by the size of its elements; the answer always equals an integer
 * since array size is a multiple of element size. Both measurements must be
 * static, otherwise the compiler cannot supply a fixed integer dimension.  The
 * implementation wraps the argument in parenthesis in order to enforce the
 * necessary operator precedence.
 * @note Beware of side effects if you pass operators in the @a array
 * expression. The macro argument evaluates twice.
 */
#define ASDimOf(array) (sizeof(array)/sizeof((array)[0]))
