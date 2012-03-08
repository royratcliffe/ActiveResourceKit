// ActiveResourceKit ARQueuedLoadingURLConnection.m
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

#import "ARQueuedLoadingURLConnection.h"
#import "ARHTTPResponse.h"

@implementation ARQueuedLoadingURLConnection

- (void)sendRequest:(NSURLRequest *)request completionHandler:(ARConnectionCompletionHandler)completionHandler
{
	[NSURLConnection sendAsynchronousRequest:request queue:[self operationQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		// Wrap the response and body together using ARHTTPResponse. Operates
		// more like Rails, where the response includes the body; but this
		// involves a subtle semantic shift for Cocoa. Under Cocoa, nil data
		// indicates an error. This is a subtle change in success-failure
		// semantics. Cocoa's URL connection interfaces answer non-nil data on
		// success, nil data on failure. Hence you would typically check for
		// existence of data to determine success or failure. You can still do
		// so by asking for the response body. However, you might also check for
		// non-existing error assuming that nil data and non-nil error
		// correspond to the same state, namely failure; while non-nil data and
		// nil error correspond to success.
		NSParameterAssert((data != nil && error == nil) || (data == nil && error != nil));
		completionHandler([[ARHTTPResponse alloc] initWithURLResponse:response body:data], error);
	}];
}

//------------------------------------------------------------------------------
#pragma mark                                                     Operation Queue
//------------------------------------------------------------------------------

@synthesize operationQueue;

@end
