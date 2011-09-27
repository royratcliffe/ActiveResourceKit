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

@interface ARBase(Private)

- (id<ARFormat>)defaultFormat;
- (NSString *)defaultPrefix;
- (NSString *)defaultElementName;
- (NSString *)defaultCollectionName;

/*!
 * Sends an asynchronous GET request. When the response successfully arrives,
 * the format decodes the data. If the response body decodes successfully,
 * finally sends the decoded object (or objects) to your given completion
 * handler. Objects may be hashes (dictionaries) or arrays, or even primitives.
 */
- (void)get:(NSString *)path completionHandler:(void (^)(id object, NSError *error))completionHandler;

@end
