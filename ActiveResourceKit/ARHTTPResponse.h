// ActiveResourceKit ARHTTPResponse.h
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

/**
 * Wraps HTTP response and body.
 *
 * Apple's URL connection programming interface delivers HTTP response
 * information in two separate pieces: a response object and a block of data for
 * the response body. This class combines these two pieces together again. You
 * can pass around a response, ask for its status code, header fields and
 * body. You can also decode and replace the body if required.
 *
 * Can this class safely sub-class `NSHTTPURLResponse`? That may be possible
 * since the class does not explicitly belong to a class cluster. Nevertheless,
 * `ARHTTPResponse` does not sub-class it because the Active Resource
 * response presents a more Ruby-compatible interface. You can still access the
 * underlying Cocoa response object by sending `URLResponse`.
 */
@interface ARHTTPResponse : NSObject

/**
 * The underlying URL response object.
 */
@property(strong, NS_NONATOMIC_IOSONLY) NSHTTPURLResponse *URLResponse;

/**
 * The response body in some form.
 *
 * Note that you can rewrite the body, e.g. when handling
 * decompression. Hence the body has generic object type. It always starts out
 * as `NSData` but can become other types such as `NSString` after decoding.
 */
@property(strong, NS_NONATOMIC_IOSONLY) id body;

/**
 * Shortcut for allocating, initialising then setting the URL response
 * and body.
 *
 * Not the designated initialiser.
 */
- (id)initWithHTTPURLResponse:(NSHTTPURLResponse *)URLResponse body:(id)body;

/**
 * Creates an Active Resource HTTP response based on a response-data
 * pair, the kind typically delivered by Apple's URL connection programming
 * interface.
 * @result Answers a new HTTP response wrapper or `nil` if the given response
 * is _not_ a HTTP URL response.  Answering `nil` is an expected response
 * from this method if the requests from which the responses derive do not use
 * the HTTP protocol.
 */
- (id)initWithURLResponse:(NSURLResponse *)URLResponse body:(id)body;

- (NSInteger)code;
- (NSDictionary *)headerFields;

@end
