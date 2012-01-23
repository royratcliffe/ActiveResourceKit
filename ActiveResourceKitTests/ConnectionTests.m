// ActiveResourceKit ConnectionTests.m
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

#import "ConnectionTests.h"

// import the monolithic header at its installed location
#import <ActiveResourceKit/ActiveResourceKit.h>

@implementation ConnectionTests

- (void)testHandleResponse
{
	// valid responses: 2xx and 3xx
	for (NSNumber *code in [NSArray arrayWithObjects:[NSNumber numberWithInt:200], [NSNumber numberWithInt:299], [NSNumber numberWithInt:300], [NSNumber numberWithInt:399], nil])
	{
		NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:ActiveResourceKitTestsBaseURL() statusCode:[code integerValue] HTTPVersion:@"HTTP/1.1" headerFields:nil];
		NSError *error = [ARConnection handleHTTPResponse:response];
		STAssertNil(error, nil);
	}
}

- (void)testGet
{
	ARConnection *connection = [[ARConnection alloc] initWithSite:ActiveResourceKitTestsBaseURL()];
	NSHTTPURLResponse *HTTPResponse = nil;
	NSError *error = nil;
	NSData *data = [connection get:@"/people/1.json" headers:nil returningResponse:&HTTPResponse error:&error];
	NSDictionary *matz = [[connection format] decode:data error:&error];
	STAssertEqualObjects(@"Matz", [matz valueForKey:@"name"], nil);
}

- (void)testHead
{
	// Test against the same path as above in testGet, same headers, only the
	// HTTP request method differs: HEAD rather than GET. In response, the
	// server should answer with an empty body and response code 200.
	NSHTTPURLResponse *HTTPResponse = nil;
	NSData *data = [[[ARConnection alloc] initWithSite:ActiveResourceKitTestsBaseURL()] head:@"/people/1.json" headers:nil returningResponse:&HTTPResponse error:NULL];
	STAssertEquals([data length], (NSUInteger)0, nil);
	STAssertEquals([HTTPResponse statusCode], (NSInteger)200, nil);
}

@end
