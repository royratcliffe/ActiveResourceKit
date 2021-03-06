// ActiveResourceKit ARService+Private.h
//
// Copyright © 2011–2013, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import <ActiveResourceKit/ARService.h>
#import <ActiveResourceKit/ARConnection.h>

@class ARResource;
@class ARHTTPResponse;

/**
 * Builds a query string given a dictionary of query options.
 * @param options Dictionary (a Ruby hash) of query options.
 * @result The answer is an empty string when you pass `nil` options or the
 * options indicate an empty dictionary. This function assumes that the given
 * options are _query_ options only; they should not contain prefix options;
 * otherwise prefix options will appear in the query string. Invoking this
 * helper function assumes you have already filtered any options by splitting
 * apart prefix from query options.
 */
NSString *ARQueryStringForOptions(NSDictionary *options);

/**
 * Defines the request completion handler type.
 *
 * Request completion handlers are C blocks receiving: (1) the HTTP
 * response, (2) the `object` decoded and (3) the `error` object in case of
 * error. The response always appears. The object decoded is non-nil if the
 * response body successfully decodes according to the expected format (JSON or
 * XML) and error is `nil`. On error, object is `nil` and `error` describes
 * the error condition. Asynchronous connection methods utilise this completion
 * handler type. C blocks of this type receive completion results, whether
 * success or failure. Operation or dispatch queue assignment depends on which
 * object invokes the block.
 */
typedef void (^ARServiceRequestCompletionHandler)(ARHTTPResponse *response, id object, NSError *error);

@interface ARService(Private)

- (id<ARFormat>)defaultFormat;
- (NSString *)defaultElementName;
- (NSString *)defaultCollectionName;
- (NSString *)defaultPrimaryKey;
- (NSString *)defaultPrefixSource;

- (void)findEveryWithOptions:(NSDictionary *)options completionHandler:(void (^)(ARHTTPResponse *response, NSArray *resources, NSError *error))completionHandler;

/**
 * Instantiates a collection of active resources given a collection of
 * attributes; collection here meaning an array. The collection argument
 * specifies an array of dictionaries. Each dictionary specifies attributes for
 * a new active resource. Answers an array of newly instantiated active
 * resources.
 */
- (NSArray *)instantiateCollection:(NSArray *)collection prefixOptions:(NSDictionary *)prefixOptions;

/**
 * Instantiates a resource element (a record) using the given attributes
 * and prefix options.
 *
 * The implementation looks for a class matching the element name. It
 * converts the element name to class name by camel-casing the name. The answer
 * becomes an instance of that class if the class exists and derives from
 * ARResource. Otherwise the answer is a plain instance of ARResource.
 */
- (ARResource *)instantiateRecordWithAttributes:(NSDictionary *)attributes prefixOptions:(NSDictionary *)prefixOptions;

/**
 * Answers a set of prefix parameters based on the current prefix source. These
 * constitute the current set of prefix parameters: an array of strings without
 * the leading colon. Colon immediately followed by a word marks each parameter
 * in the prefix source.
 */
- (NSSet *)prefixParameters;

/**
 * Splits an options dictionary into two dictionaries, one containing the prefix
 * options, the other containing the leftovers, i.e. any query options.
 */
- (void)splitOptions:(NSDictionary *)options prefixOptions:(NSDictionary **)outPrefixOptions queryOptions:(NSDictionary **)outQueryOptions;

//---------------------------------------------------------------- HTTP Requests

/**
 * Sends an asynchronous GET request. Used to find a resource.
 *
 * When the response successfully arrives, the format decodes the
 * data. If the response body decodes successfully, finally sends the decoded
 * object (or objects) to your given completion handler. Objects may be hashes
 * (dictionaries) or arrays, or even primitives.
 */
- (void)get:(NSString *)path completionHandler:(ARServiceRequestCompletionHandler)completionHandler;

/**
 * Used to delete resources. Sends an asynchronous DELETE request.
 */
- (void)delete:(NSString *)path completionHandler:(ARServiceRequestCompletionHandler)completionHandler;

/**
 * Sends an asynchronous PUT request.
 *
 * PUT is idempotent, meaning that multiple PUT requests result in an
 * identical resource state. There should be no side effects. PUT really amounts
 * to an “upsert” database operation where it updates the resource if it already
 * exists but alternatively creates the resource if it does not already exist.
 */
- (void)put:(NSString *)path body:(NSData *)data completionHandler:(ARServiceRequestCompletionHandler)completionHandler;

/**
 * Sends an asynchronous POST request.
 *
 * POST is not idempotent.
 */
- (void)post:(NSString *)path body:(NSData *)data completionHandler:(ARServiceRequestCompletionHandler)completionHandler;

/**
 * Used to obtain meta-information about resources, whether they exist or
 * their size. Sends an asynchronous HEAD request.
 */
- (void)head:(NSString *)path completionHandler:(ARServiceRequestCompletionHandler)completionHandler;

/**
 * Submits an asynchronous request, returning immediately.
 *
 * Constructs a request object and asynchronously transmits it to the
 * remote RESTful service. The completion handler executes in the resource
 * service's operation queue, or the current queue (the operation queue running at
 * the time of the request) if the resource service has no queue.
 *
 * The completion handler receives three arguments: the HTTP response, the
 * decoded object and any error. The decoded object derives from the response
 * body, decoded according to the service format. Decoding itself can encounter
 * errors. If successful, the completion handler receives a non-nil object and a
 * `nil` error. If the response is not an HTTP-based response, the completion
 * handler receives a `nil` `response` argument and an
 * `ARResponseIsNotHTTPError`.
 */
- (void)requestHTTPMethod:(NSString *)HTTPMethod path:(NSString *)path body:(NSData *)data completionHandler:(ARServiceRequestCompletionHandler)completionHandler;

/**
 * Answers a decoding handler which, in turn, after decoding, invokes
 * another given completion block.
 *
 * Active Resource Kit methods utilise this common response block for
 * decoding according to the required format. In fact, the decoding does a
 * little more than just decode the format. It also handles URL response to HTTP
 * response type casting. The latter carries more information including header
 * fields and HTTP status code.
 */
- (ARConnectionCompletionHandler)decodeHandlerWithCompletionHandler:(ARServiceRequestCompletionHandler)completionHandler;

@end
