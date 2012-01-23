// ActiveResourceKit ARConnection.m
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

#import "ARConnection.h"
#import "ARConnection+Private.h"

#import "ARJSONFormat.h"
#import "ARHTTPMethods.h"
#import "ARErrors.h"

@implementation ARConnection

@synthesize site    = _site;
@synthesize format  = _format;
@synthesize timeout = _timeout;

//------------------------------------------------------------------------------
#pragma mark                                                        Initialisers
//------------------------------------------------------------------------------

// designated initialiser
- (id)init
{
	self = [super init];
	if (self)
	{
		[self setTimeout:60.0];
	}
	return self;
}

- (id)initWithSite:(NSURL *)site format:(id<ARFormat>)format
{
	self = [self init];
	if (self)
	{
		[self setSite:site];
		[self setFormat:format];
	}
	return self;
}

- (id)initWithSite:(NSURL *)site
{
	return [self initWithSite:site format:[ARJSONFormat JSONFormat]];
}

- (NSURLConnection *)HTTPWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
	return [NSURLConnection connectionWithRequest:request delegate:delegate];
}

+ (NSError *)handleHTTPResponse:(NSHTTPURLResponse *)HTTPResponse
{
	NSInteger code;
	switch ([HTTPResponse statusCode])
	{
		case 301:
		case 302:
		case 303:
		case 307:
			// 301: moved permanently (redirect)
			// 302: found (but redirect)
			// 303: see other (redirect)
			// 307: temporarily redirected (redirect)
			code = ARRedirectionErrorCode;
			break;
		case 400:
			code = ARBadRequestErrorCode;
			break;
		case 401:
			code = ARUnauthorizedAccessErrorCode;
			break;
		case 403:
			code = ARForbiddenAccessErrorCode;
			break;
		case 404:
			code = ARResourceNotFoundErrorCode;
			break;
		case 405:
			code = ARMethodNotAllowedErrorCode;
			break;
		case 409:
			code = ARResourceConflictErrorCode;
			break;
		case 410:
			code = ARResourceGoneErrorCode;
			break;
		case 422:
			code = ARResourceInvalidErrorCode;
			break;
		default:
			if (200 <= [HTTPResponse statusCode] && [HTTPResponse statusCode] < 400)
			{
				code = '    ';
			}
			else if (401 <= [HTTPResponse statusCode] && [HTTPResponse statusCode] < 500)
			{
				code = ARClientErrorCode;
			}
			else if (500 <= [HTTPResponse statusCode] && [HTTPResponse statusCode] < 600)
			{
				code = ARServerErrorCode;
			}
			else
			{
				code = ARConnectionErrorCode;
			}
	}
	NSError *error;
	if (code != '    ')
	{
		NSString *localizedDescription = [NSHTTPURLResponse localizedStringForStatusCode:[HTTPResponse statusCode]];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:HTTPResponse, ARConnectionHTTPResponseKey, localizedDescription, NSLocalizedDescriptionKey, nil];
		error = [NSError errorWithDomain:ARConnectionErrorDomain code:code userInfo:userInfo];
	}
	else
	{
		error = nil;
	}
	return error;
}

//------------------------------------------------------------------------------
#pragma mark                                                          HTTP Verbs
//------------------------------------------------------------------------------

- (NSData *)get:(NSString *)path
		headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		  error:(NSError **)outError;
{
	return [self requestWithHTTPMethod:ARHTTPGetMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)delete:(NSString *)path
		   headers:(NSDictionary *)headers
 returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
			 error:(NSError **)outError;
{
	return [self requestWithHTTPMethod:ARHTTPDeleteMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)put:(NSString *)path
		headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		  error:(NSError **)outError;
{
	return [self requestWithHTTPMethod:ARHTTPPutMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)post:(NSString *)path
		 headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		   error:(NSError **)outError;
{
	return [self requestWithHTTPMethod:ARHTTPPostMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)head:(NSString *)path
		 headers:(NSDictionary *)headers
returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
		   error:(NSError **)outError;
{
	return [self requestWithHTTPMethod:ARHTTPHeadMethod path:path headers:headers returningResponse:outHTTPResponse error:outError];
}

- (NSData *)requestWithHTTPMethod:(NSString *)HTTPMethod
							 path:(NSString *)path
						  headers:(NSDictionary *)headers
				returningResponse:(NSHTTPURLResponse *__autoreleasing *)outHTTPResponse
							error:(NSError **)outError
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

//------------------------------------------------------------------------------
#pragma mark                                                   Building Requests
//------------------------------------------------------------------------------

- (NSMutableURLRequest *)getRequestForPath:(NSString *)path headers:(NSDictionary *)headers
{
	return [self requestForHTTPMethod:ARHTTPGetMethod path:path headers:headers];
}

- (NSMutableURLRequest *)deleteRequestForPath:(NSString *)path headers:(NSDictionary *)headers
{
	return [self requestForHTTPMethod:ARHTTPDeleteMethod path:path headers:headers];
}

- (NSMutableURLRequest *)putRequestForPath:(NSString *)path headers:(NSDictionary *)headers
{
	return [self requestForHTTPMethod:ARHTTPPutMethod path:path headers:headers];
}

- (NSMutableURLRequest *)postRequestForPath:(NSString *)path headers:(NSDictionary *)headers
{
	return [self requestForHTTPMethod:ARHTTPPostMethod path:path headers:headers];
}

- (NSMutableURLRequest *)headRequestForPath:(NSString *)path headers:(NSDictionary *)headers
{
	return [self requestForHTTPMethod:ARHTTPHeadMethod path:path headers:headers];
}

- (NSMutableURLRequest *)requestForHTTPMethod:(NSString *)HTTPMethod path:(NSString *)path headers:(NSDictionary *)headers
{
	NSURL *URL = [NSURL URLWithString:path relativeToURL:[self site]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:[self timeout]];
	NSMutableDictionary *headerFields = [NSMutableDictionary dictionaryWithDictionary:[request allHTTPHeaderFields]];
	[headerFields addEntriesFromDictionary:[self buildRequestHeaderFieldsUsingHeaders:headers forHTTPMethod:HTTPMethod]];
	[request setAllHTTPHeaderFields:headerFields];
	[request setHTTPMethod:HTTPMethod];
	return request;
}

@end
