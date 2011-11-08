// ActiveResourceKit ARBase+Private.h
//
// Copyright © 2011, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import <ActiveResourceKit/ARBase.h>

@class AResource;

/*!
 * @brief Builds a query string given a dictionary of query options.
 * @param options Dictionary (a Ruby hash) of query options.
 * @result The answer is an empty string when you pass @c nil options or the
 * options indicate an empty dictionary. This function assumes that the given
 * options are @e query options only; they should not contain prefix options;
 * otherwise prefix options will appear in the query string. Invoking this
 * helper function assumes you have already filtered any options by splitting
 * apart prefix from query options.
 */
NSString *ARQueryStringForOptions(NSDictionary *options);

/*!
 * @brief Defines the request completion handler type.
 * @details Request completion handlers are C blocks receiving: (1) the HTTP
 * response, (2) the @a object decoded and (3) the @a error object in case of
 * error. The response always appears. The object decoded is non-nil if the
 * response body successfully decodes according to the expected format (JSON or
 * XML) and error is @c nil. On error, object is @c nil and @a error describes
 * the error condition.
 */
typedef void (^ARBaseRequestCompletionHandler)(NSHTTPURLResponse *HTTPResponse, id object, NSError *error);

@interface ARBase(Private)

- (id<ARFormat>)defaultFormat;
- (NSString *)defaultElementName;
- (NSString *)defaultCollectionName;
- (NSString *)defaultPrimaryKey;
- (NSString *)defaultPrefixSource;

- (void)findEveryWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSArray *resources, NSError *error))completionHandler;

/*!
 * Instantiates a collection of active resources given a collection of
 * attributes; collection here meaning an array. The collection argument
 * specifies an array of dictionaries. Each dictionary specifies attributes for
 * a new active resource. Answers an array of newly instantiated active
 * resources.
 */
- (NSArray *)instantiateCollection:(NSArray *)collection prefixOptions:(NSDictionary *)prefixOptions;

/*!
 * @brief Instantiates a resource element (a record) using the given attributes
 * and prefix options.
 * @details The implementation looks for a class matching the element name. It
 * converts the element name to class name by camel-casing the name. The answer
 * becomes an instance of that class if the class exists and derives from
 * AResource. Otherwise the answer is a plain instance of AResource.
 */
- (AResource *)instantiateRecordWithAttributes:(NSDictionary *)attributes prefixOptions:(NSDictionary *)prefixOptions;

/*!
 * Answers a set of prefix parameters based on the current prefix source. These
 * constitute the current set of prefix parameters: an array of strings without
 * the leading colon. Colon immediately followed by a word marks each parameter
 * in the prefix source.
 */
- (NSSet *)prefixParameters;

/*!
 * Splits an options dictionary into two dictionaries, one containing the prefix
 * options, the other containing the leftovers, i.e. any query options.
 */
- (void)splitOptions:(NSDictionary *)options prefixOptions:(NSDictionary **)outPrefixOptions queryOptions:(NSDictionary **)outQueryOptions;

//---------------------------------------------------------------- HTTP Requests

/*!
 * @brief Sends an asynchronous GET request. Used to find a resource.
 * @details When the response successfully arrives, the format decodes the
 * data. If the response body decodes successfully, finally sends the decoded
 * object (or objects) to your given completion handler. Objects may be hashes
 * (dictionaries) or arrays, or even primitives.
 */
- (void)get:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler;

/*!
 * @brief Used to delete resources. Sends an asynchronous DELETE request.
 */
- (void)delete:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler;

/*!
 * @brief Sends an asynchronous PUT request.
 * @details PUT is idempotent, meaning that multiple PUT requests result in an
 * identical resource state. There should be no side effects. PUT really amounts
 * to an “upsert” database operation where it updates the resource if it already
 * exists but alternatively creates the resource if it does not already exist.
 */
- (void)put:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler;

/*!
 * @brief Sends an asynchronous POST request.
 * @details POST is not idempotent.
 */
- (void)post:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler;

/*!
 * @brief Used to obtain meta-information about resources, whether they exist or
 * their size. Sends an asynchronous HEAD request.
 */
- (void)head:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler;

/*!
 * @brief Submits an asynchronous request, returning immediately.
 * @details Constructs a request object and asynchronously transmits it to the
 * remote RESTful service. The completion handler executes in the resource
 * base's operation queue, or the current queue (the operation queue running at
 * the time of the request) if the resource base has no queue.
 *
 * The completion handler receives three arguments: the HTTP response, the
 * decoded object and any error. The decoded object derives from the response
 * body, decoded according to the base format. Decoding itself can encounter
 * errors. If successful, the completion handler receives a non-nil object and a
 * @c nil error. If the response is not an HTTP-based response, the completion
 * handler receives a @c nil response @a HTTPResponse argument and an @ref
 * ARResponseIsNotHTTPError.
 */
- (void)requestHTTPMethod:(NSString *)HTTPMethod path:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler;

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
