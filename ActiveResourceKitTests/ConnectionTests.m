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
	NSError *(^handleHTTPResponse)(NSInteger statusCode) = ^(NSInteger statusCode) {
		return [ARConnection handleHTTPResponse:[[NSHTTPURLResponse alloc] initWithURL:ActiveResourceKitTestsBaseURL() statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:nil]];
	};
	// valid responses: 2xx and 3xx
	for (NSNumber *code in [NSArray arrayWithObjects:[NSNumber numberWithInt:200], [NSNumber numberWithInt:299], [NSNumber numberWithInt:300], [NSNumber numberWithInt:399], nil])
	{
		STAssertNil(handleHTTPResponse([code integerValue]), nil);
	}
	// redirection
	NSArray *redirectCodes = [NSArray arrayWithObjects:[NSNumber numberWithInt:301], [NSNumber numberWithInt:302], [NSNumber numberWithInt:303], [NSNumber numberWithInt:307], nil];
	NSArray *redirectDescriptions = [NSArray arrayWithObjects:@"moved permanently", @"found", @"see other", @"temporarily redirected", nil];
	NSDictionary *redirectDescriptionForCode = [NSDictionary dictionaryWithObjects:redirectDescriptions forKeys:redirectCodes];
	for (NSNumber *code in redirectCodes)
	{
		NSError *error = handleHTTPResponse([code integerValue]);
		STAssertNotNil(error, nil);
		STAssertEquals([error code], (NSInteger)kARRedirectionErrorCode, nil);
		STAssertEqualObjects([[error userInfo] objectForKey:NSLocalizedDescriptionKey], [redirectDescriptionForCode objectForKey:code], nil);
	}
	// client errors: 4xx
	struct
	{
		NSInteger statusCode;
		NSInteger errorCode;
	}
	clientCodesAndErrors[] =
	{
		{ 400, (NSInteger)kARBadRequestErrorCode },
		{ 401, (NSInteger)kARUnauthorizedAccessErrorCode },
		{ 403, (NSInteger)kARForbiddenAccessErrorCode },
		{ 404, (NSInteger)kARResourceNotFoundErrorCode },
		{ 405, (NSInteger)kARMethodNotAllowedErrorCode },
		{ 409, (NSInteger)kARResourceConflictErrorCode },
		{ 410, (NSInteger)kARResourceGoneErrorCode },
		{ 422, (NSInteger)kARResourceInvalidErrorCode },
	};
	NSUInteger const clientCodesAndErrorsCount = sizeof(clientCodesAndErrors)/sizeof(clientCodesAndErrors[0]);
	for (NSUInteger i = 0; i < clientCodesAndErrorsCount; i++)
	{
		STAssertEquals([handleHTTPResponse(clientCodesAndErrors[i].statusCode) code], clientCodesAndErrors[i].errorCode, nil);
	}
	for (NSInteger statusCode = 402; statusCode <= 499; statusCode++)
	{
		NSUInteger i;
		for (i = 0; i < clientCodesAndErrorsCount && statusCode != clientCodesAndErrors[i].statusCode; i++);
		if (i == clientCodesAndErrorsCount)
		{
			STAssertEquals([handleHTTPResponse(statusCode) code], (NSInteger)kARClientErrorCode, nil);
		}
	}
	// server errors: 5xx
	for (NSInteger statusCode = 500; statusCode <= 599; statusCode++)
	{
		STAssertEquals([handleHTTPResponse(statusCode) code], (NSInteger)kARServerErrorCode, nil);
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
