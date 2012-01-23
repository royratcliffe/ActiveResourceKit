// ActiveResourceKit ARConnection+Private.h
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <ActiveResourceKit/ARConnection.h>

@interface ARConnection(Private)

/*!
 * @brief Supplies default headers for the connection; none by default unless a
 * sub-class overrides this method.
 * @details Sub-classes can override this method to provide headers required for
 * the underlying connection. Please note however, the implementation
 * subsequently overwrites the format header. Similarly, user-supplied headers
 * override headers injected here as defaults.
 *
 * @par Interface Note
 * Rails' Active Resource gem calls this method @c default_header,
 * singular. This interface makes it @em plural since the answer is a dictionary
 * of headers.
 */
- (NSDictionary *)defaultHeaders;

- (NSDictionary *)buildRequestHeaderFieldsUsingHeaders:(NSDictionary *)headers forHTTPMethod:(NSString *)HTTPMethod;

//----------------------------------------------------- Format Header for Method

/*!
 * @brief Answers a format header for the given HTTP request method.
 * @param HTTPMethod String containing either GET, PUT, POST, DELETE or HEAD
 * that specifies the HTTP request method. Case must match.
 * @result A dictionary containing either an Accept or Content-Type format
 * header along with the appropriate MIME type. Merge this dictionary with any
 * other request header fields.
 */
- (NSDictionary *)HTTPFormatHeaderForHTTPMethod:(NSString *)HTTPMethod;

@end
