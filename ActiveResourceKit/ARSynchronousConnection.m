// ActiveResourceKit ARSynchronousConnection.m
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

#import "ARSynchronousConnection.h"
#import "ARHTTPMethods.h"

@implementation ARSynchronousConnection

//------------------------------------------------------------------------------
#pragma mark                                                          HTTP Verbs
//------------------------------------------------------------------------------

- (NSData *)get:(NSString *)path
		headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		  error:(NSError *__autoreleasing *)outError;
{
	return [self requestWithHTTPMethod:ARHTTPGetMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)delete:(NSString *)path
		   headers:(NSDictionary *)headers
 returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
			 error:(NSError *__autoreleasing *)outError;
{
	return [self requestWithHTTPMethod:ARHTTPDeleteMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)put:(NSString *)path
		headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		  error:(NSError *__autoreleasing *)outError;
{
	return [self requestWithHTTPMethod:ARHTTPPutMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)post:(NSString *)path
		 headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		   error:(NSError *__autoreleasing *)outError;
{
	return [self requestWithHTTPMethod:ARHTTPPostMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)head:(NSString *)path
		 headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		   error:(NSError *__autoreleasing *)outError;
{
	return [self requestWithHTTPMethod:ARHTTPHeadMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)requestWithHTTPMethod:(NSString *)HTTPMethod
							 path:(NSString *)path
						  headers:(NSDictionary *)headers
				returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
							error:(NSError *__autoreleasing *)outError
{
	NSMutableURLRequest *request = [self requestForHTTPMethod:HTTPMethod path:path headers:headers];
	NSURLResponse *__autoreleasing response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:outError];
	if (outHTTPResponse)
	{
		*outHTTPResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
	}
	return data;
}

@end
