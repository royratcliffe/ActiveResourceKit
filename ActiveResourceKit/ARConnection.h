// ActiveResourceKit ARConnection.h
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

#import <ActiveResourceKit/ARFormat.h>

enum
{
	/*!
	 * @brief Code for redirection; not really an error code as such.
	 */
	kARRedirectionErrorCode        = 'redi',
	
	kARBadRequestErrorCode         = 'badr',
	kARUnauthorizedAccessErrorCode = 'auth',
	kARForbiddenAccessErrorCode    = 'forb',
	kARResourceNotFoundErrorCode   = 'reso',
	kARMethodNotAllowedErrorCode   = 'meth',
	kARResourceConflictErrorCode   = 'conf',
	kARResourceGoneErrorCode       = 'gone',
	kARResourceInvalidErrorCode    = 'inva',
	kARClientErrorCode             = 'clie',
	kARServerErrorCode             = 'serv',
	kARConnectionErrorCode         = 'conn',
};

extern NSString *const kARConnectionErrorDomain;
extern NSString *const kARConnectionHTTPResponseKey;

/*!
 * @brief Connects to a site using a format.
 */
@interface ARConnection : NSObject

@property(strong, NS_NONATOMIC_IOSONLY) NSURL *site;

@property(strong, NS_NONATOMIC_IOSONLY) id<ARFormat> format;

@property(assign, NS_NONATOMIC_IOSONLY) NSTimeInterval timeout;

//----------------------------------------------------------------- Initialisers

// Parameterised initialisers: the following initialisers just act as shortcuts
// for running the default initialiser then sending the site and format using
// accessors. Initialising a connection with only a site URL prepares the new
// connection for JSON-formatted interactions. This mimics Rails behaviour where
// JSON connections initialise by default. You can subsequently change the
// format, of course, using -setFormat:newFormat.

- (id)initWithSite:(NSURL *)site format:(id<ARFormat>)format;
- (id)initWithSite:(NSURL *)site;

/*!
 * @brief Answers an asynchronous HTTP connection ready for use.
 * @details Unlike Rails, the Cocoa connection requires a request upfront. You
 * supply the request as a parameter for the connection constructor. You do @em
 * not construct first then configure the request second.
 */
- (NSURLConnection *)HTTPWithRequest:(NSURLRequest *)request delegate:(id)delegate;

/*!
 * @brief Decides how to handle the given HTTP response based on the response
 * status code.
 * @details The Rails implementation of @c handle_response checks the status
 * code and raises an exception for any status outside the normal range. The
 * Objective-C implementation does @em not raise exceptions however, by
 * design. Instead, “handling a response” refers to deriving an error object for
 * an otherwise-successful response.
 * @result Answers an @c NSError object if the response indicates a problem; @c
 * nil otherwise. The error object's error code and localised description
 * outline the issue. You can also retrieve the HTTP response object itself by
 * accessing the error's user information dictionary with the @ref
 * kARConnectionHTTPResponseKey key.
 */
- (NSError *)handleHTTPResponse:(NSHTTPURLResponse *)HTTPResponse;

//------------------------------------------------------------------- HTTP Verbs

- (NSData *)get:(NSString *)path headers:(NSDictionary *)headers returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse error:(NSError **)outError;

- (NSData *)delete:(NSString *)path headers:(NSDictionary *)headers returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse error:(NSError **)outError;

- (NSData *)put:(NSString *)path headers:(NSDictionary *)headers returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse error:(NSError **)outError;

- (NSData *)post:(NSString *)path headers:(NSDictionary *)headers returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse error:(NSError **)outError;

- (NSData *)head:(NSString *)path headers:(NSDictionary *)headers returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse error:(NSError **)outError;

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
- (NSData *)requestWithHTTPMethod:(NSString *)HTTPMethod path:(NSString *)path headers:(NSDictionary *)headers returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse error:(NSError **)outError;

//------------------------------------------------------------ Building Requests

/*!
 * @brief Builds a GET request for the given @a path with the given @a headers.
 * @details Shortcut for -[ARConnection requestForHTTPMethod:kARHTTPGetMethod
 * path:path headers:headers].
 * @par Please Note
 * This method builds a GET request for the given path with the given
 * headers. It does not @em get the request. The term “get” refers to the HTTP
 * method and @em not to the act of getting a request as in a getter accessor.
 */
- (NSMutableURLRequest *)getRequestForPath:(NSString *)path headers:(NSString *)headers;

- (NSMutableURLRequest *)deleteRequestForPath:(NSString *)path headers:(NSString *)headers;

- (NSMutableURLRequest *)putRequestForPath:(NSString *)path headers:(NSString *)headers;

- (NSMutableURLRequest *)postRequestForPath:(NSString *)path headers:(NSString *)headers;

- (NSMutableURLRequest *)headRequestForPath:(NSString *)path headers:(NSString *)headers;

/*!
 * @brief Builds a mutable HTTP request given a HTTP method, a path and headers.
 * @details The request site and timeout originates with the message
 * receiver. You can open either an asynchronous connection using the request,
 * or send it synchronously and wait for the response. You might even enqueue
 * the request in a pool of pending requests. This interface method exists and
 * belongs to the public API in order to provide a flexible approach to handling
 * connections: asynchronous or synchronous, queued or immediate. The method
 * simply prepares the request ready to go.
 */
- (NSMutableURLRequest *)requestForHTTPMethod:(NSString *)HTTPMethod path:(NSString *)path headers:(NSDictionary *)headers;

@end
