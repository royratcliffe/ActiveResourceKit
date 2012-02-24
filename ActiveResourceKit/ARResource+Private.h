// ActiveResourceKit ARResource+Private.h
//
// Copyright © 2011, 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import <ActiveResourceKit/ARResource.h>

@class ARHTTPResponse;

/*!
 * @brief Extracts the resource identifier from the given HTTP response.
 * @details The HTTP response includes a Location header field specifying the
 * resource's full resource location. Rails places the resource ID at the last
 * element in the location path. The implementation extracts this element using
 * a regular expression.
 * @result Answers an NSNumber numerical identifier based on the response
 * location field. Answers @c nil if the response does not contain a Location
 * header, or if the Location field does not match the format @c "/foo/bar/1".
 */
NSNumber *ARIDFromResponse(ARHTTPResponse *response);

/*!
 * @brief Determines whether the HTTP 1.1 specification allows a response to
 * have a body (see section 4.4.1 of the specification).
 */
BOOL ARResponseCodeAllowsBody(NSInteger code);

@interface ARResource(Private)

- (void)updateWithCompletionHandler:(void (^)(ARHTTPResponse *response, NSError *error))completionHandler;

- (void)createWithCompletionHandler:(void (^)(ARHTTPResponse *response, NSError *error))completionHandler;

/*!
 * @param HTTPResponse A HTTP response wrapper.
 * @param attributes Set of attributes decoded from the response body.
 */
- (void)loadAttributesFromResponse:(ARHTTPResponse *)response attributes:(NSDictionary *)attributes;

@end
