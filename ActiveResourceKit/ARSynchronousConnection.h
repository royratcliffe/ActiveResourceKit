// ActiveResourceKit ARSynchronousConnection.h
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

#import <ActiveResourceKit/ARConnection.h>

@interface ARSynchronousConnection : ARConnection

//------------------------------------------------------------------- HTTP Verbs

- (NSData *)get:(NSString *)path
		headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		  error:(NSError *__autoreleasing *)outError;

- (NSData *)delete:(NSString *)path
headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
error:(NSError *__autoreleasing *)outError;

- (NSData *)put:(NSString *)path
		headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		  error:(NSError *__autoreleasing *)outError;

- (NSData *)post:(NSString *)path
		 headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		   error:(NSError *__autoreleasing *)outError;

- (NSData *)head:(NSString *)path
		 headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		   error:(NSError *__autoreleasing *)outError;

/*!
 * @brief Performs a @em synchronous HTTP request.
 * @details The implementation handles conversion of the basic URL response to a
 * HTTP response. The latter carries more information including header fields
 * and HTTP status code.
 * @param path URL path element to apply to the site's base URL.
 * @param headers Zero or more header fields. These override all other headers
 * within the request, including authorisation and formatting headers. Use @c
 * nil for no headers.
 * @param outHTTPResponse Receives the HTTP response if not @c NULL.
 * @param outError Receives any error if not @c NULL.
 * @result Answers the response body as raw data bytes if successful. Answers @c
 * nil on error.
 */
- (NSData *)requestWithHTTPMethod:(NSString *)HTTPMethod
							 path:(NSString *)path
						  headers:(NSDictionary *)headers
				returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
							error:(NSError *__autoreleasing *)outError;

@end
