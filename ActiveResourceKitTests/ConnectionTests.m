// ActiveResourceKitTests ConnectionTests.m
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

- (void)testErrorForResponse
{
	NSError *(^errorForHTTPResponse)(NSInteger statusCode) = ^(NSInteger statusCode) {
		return [ARConnection errorForHTTPResponse:[[NSHTTPURLResponse alloc] initWithURL:ActiveResourceKitTestsBaseURL() statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:nil]];
	};
	// valid responses: 2xx and 3xx
	for (NSNumber *code in [NSArray arrayWithObjects:[NSNumber numberWithInt:200], [NSNumber numberWithInt:299], [NSNumber numberWithInt:300], [NSNumber numberWithInt:399], nil])
	{
		STAssertNil(errorForHTTPResponse([code integerValue]), nil);
	}
	// redirection
	NSArray *redirectCodes = [NSArray arrayWithObjects:[NSNumber numberWithInt:301], [NSNumber numberWithInt:302], [NSNumber numberWithInt:303], [NSNumber numberWithInt:307], nil];
	NSArray *redirectDescriptions = [NSArray arrayWithObjects:@"moved permanently", @"found", @"see other", @"temporarily redirected", nil];
	NSDictionary *redirectDescriptionForCode = [NSDictionary dictionaryWithObjects:redirectDescriptions forKeys:redirectCodes];
	for (NSNumber *code in redirectCodes)
	{
		NSError *error = errorForHTTPResponse([code integerValue]);
		STAssertNotNil(error, nil);
		STAssertEquals([error code], (NSInteger)ARRedirectionErrorCode, nil);
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
		{ 400, (NSInteger)ARBadRequestErrorCode },
		{ 401, (NSInteger)ARUnauthorizedAccessErrorCode },
		{ 403, (NSInteger)ARForbiddenAccessErrorCode },
		{ 404, (NSInteger)ARResourceNotFoundErrorCode },
		{ 405, (NSInteger)ARMethodNotAllowedErrorCode },
		{ 409, (NSInteger)ARResourceConflictErrorCode },
		{ 410, (NSInteger)ARResourceGoneErrorCode },
		{ 422, (NSInteger)ARResourceInvalidErrorCode },
	};
	for (NSUInteger i = 0; i < ASDimOf(clientCodesAndErrors); i++)
	{
		STAssertEquals([errorForHTTPResponse(clientCodesAndErrors[i].statusCode) code], clientCodesAndErrors[i].errorCode, nil);
	}
	for (NSInteger statusCode = 402; statusCode <= 499; statusCode++)
	{
		NSUInteger i;
		for (i = 0; i < ASDimOf(clientCodesAndErrors) && statusCode != clientCodesAndErrors[i].statusCode; i++);
		if (i == ASDimOf(clientCodesAndErrors))
		{
			STAssertEquals([errorForHTTPResponse(statusCode) code], (NSInteger)ARClientErrorCode, nil);
		}
	}
	// server errors: 5xx
	for (NSInteger statusCode = 500; statusCode <= 599; statusCode++)
	{
		STAssertEquals([errorForHTTPResponse(statusCode) code], (NSInteger)ARServerErrorCode, nil);
	}
}

- (void)testGet
{
	ARSynchronousLoadingURLConnection *connection = [[ARSynchronousLoadingURLConnection alloc] initWithSite:ActiveResourceKitTestsBaseURL()];
	NSHTTPURLResponse *HTTPResponse = nil;
	NSError *error = nil;
	NSMutableURLRequest *request = [connection requestForHTTPMethod:ARHTTPGetMethod path:@"/people/1.json" headers:nil];
	NSData *data = [connection sendRequest:request returningResponse:&HTTPResponse error:&error];
	NSDictionary *matz = [[connection format] decode:data error:&error];
	STAssertEqualObjects(@"Matz", [matz valueForKey:@"name"], nil);
}

- (void)testHead
{
	// Test against the same path as above in testGet, same headers, only the
	// HTTP request method differs: HEAD rather than GET. In response, the
	// server should answer with an empty body and response code 200.
	NSHTTPURLResponse *HTTPResponse = nil;
	ARSynchronousLoadingURLConnection *connection = [[ARSynchronousLoadingURLConnection alloc] initWithSite:ActiveResourceKitTestsBaseURL()];
	NSMutableURLRequest *request = [connection requestForHTTPMethod:ARHTTPHeadMethod path:@"/people/1.json" headers:nil];
	NSData *data = [connection sendRequest:request returningResponse:&HTTPResponse error:NULL];
	STAssertEquals([data length], (NSUInteger)0, nil);
	STAssertEquals([HTTPResponse statusCode], (NSInteger)200, nil);
}

- (void)testGetWithHeader
{
	ARSynchronousLoadingURLConnection *connection = [[ARSynchronousLoadingURLConnection alloc] initWithSite:ActiveResourceKitTestsBaseURL()];
	NSHTTPURLResponse *HTTPResponse = nil;
	NSDictionary *headers = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
	NSMutableURLRequest *request = [connection requestForHTTPMethod:ARHTTPGetMethod path:@"/people/2.json" headers:headers];
	NSData *data = [connection sendRequest:request returningResponse:&HTTPResponse error:NULL];
	// This is not a real test of GET with headers. The test cannot assert
	// anything about headers being successfully sent along with the GET
	// request; the server does not echo the headers. However, if you check the
	// server log at log/thin.log, you should see traces of a GET request
	// containing, amongst other bits and pieces, the following:
	//
	//	GET /people/2.json HTTP/1.1
	//	Host: localhost:3000
	//	Accept: application/json
	//	key: value
	//	Accept-Language: en-gb
	//	Accept-Encoding: gzip, deflate
	//	Connection: keep-alive
	//
	NSDictionary *david = [[connection format] decode:data error:NULL];
	STAssertEqualObjects(@"David", [david valueForKey:@"name"], nil);
}

- (void)testPost
{
	NSHTTPURLResponse *HTTPResponse = nil;
	ARSynchronousLoadingURLConnection *connection = [[ARSynchronousLoadingURLConnection alloc] initWithSite:ActiveResourceKitTestsBaseURL()];
	NSMutableURLRequest *request = [connection requestForHTTPMethod:ARHTTPPostMethod path:@"/people.json" headers:nil];
	[connection sendRequest:request returningResponse:&HTTPResponse error:NULL];
	STAssertNotNil([[HTTPResponse allHeaderFields] objectForKey:@"Location"], nil);
}

@end
