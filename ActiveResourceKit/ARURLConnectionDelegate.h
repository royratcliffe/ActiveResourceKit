// ActiveResourceKit ARURLConnectionDelegate.h
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

@class ARHTTPResponse;

/**
 * Implements a simple connection delegate designed for collecting the
 * response, including the body data, and for working around SSL challenges.
 */
@interface ARURLConnectionDelegate : NSObject
// Connection delegate is Data or non-Data according to platform. Mac OS X and
// iOS diverge with respect to URL connection delegate protocols. iOS divides up
// the protocol by inheritance whereas OS X combines all the delegate methods
// into one big protocol. On iOS, the connection "data" delegate protocol
// inherits from the connection delegate protocol. The Active Resource Kit
// connection delegate, used by delegated connections, implements both plain
// connection and data-oriented protocols. Adjust the definition according to
// target: either OS X or iOS.
#if __MAC_OS_X_VERSION_MIN_REQUIRED
<NSURLConnectionDelegate>
#endif
#if __IPHONE_OS_VERSION_MIN_REQUIRED
<NSURLConnectionDataDelegate>
#endif

@property(copy) void (^completionHandler)(ARHTTPResponse *response, NSError *error);
@property(strong) NSURLResponse *response;
@property(strong) NSMutableData *data;

@end
