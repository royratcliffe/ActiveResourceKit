// ActiveResourceKit ARBase+Private.m
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

#import "ARBase+Private.h"
#import "ARConnection.h"

#import <ActiveResourceKit/ActiveResourceKit.h>
#import <ActiveModelKit/ActiveModelKit.h>
#import <ActiveSupportKit/ActiveSupportKit.h>

NSString *const kARFromKey = @"from";
NSString *const kARParamsKey = @"params";

NSString *ARQueryStringForOptions(NSDictionary *options)
{
	return options == nil || [options count] == 0 ? @"" : [NSString stringWithFormat:@"?%@", [options toQueryWithNamespace:nil]];
}

/*!
 * @brief Implements a simple connection delegate designed for collecting the
 * response, including the body data, and for working around SSL challenges.
 */
@interface ARURLConnectionDelegate : NSObject<NSURLConnectionDelegate>

@property(copy) void (^completionHandler)(NSURLResponse *response, NSData *data, NSError *error);
@property(strong) NSURLResponse *response;
@property(strong) NSMutableData *data;

@end

@implementation ARBase(Private)

- (id<ARFormat>)defaultFormat
{
	return [ARJSONFormat JSONFormat];
}

- (NSString *)defaultElementName
{
	return [[[AMName alloc] initWithClass:[self class]] element];
}

- (NSString *)defaultCollectionName
{
	return [[ASInflector defaultInflector] pluralize:[self elementNameLazily]];
}

- (NSString *)defaultPrimaryKey
{
	return @"id";
}

- (NSString *)defaultPrefixSource
{
	return [[self site] path];
}

- (void)findEveryWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSArray *resources, NSError *error))completionHandler
{
	NSString *path;
	NSDictionary *prefixOptions;
	NSString *from = [options objectForKey:kARFromKey];
	if (from && [from isKindOfClass:[NSString class]])
	{
		prefixOptions = nil;
		path = [NSString stringWithFormat:@"%@%@", from, ARQueryStringForOptions([options objectForKey:kARParamsKey])];
	}
	else
	{
		NSDictionary *queryOptions = nil;
		[self splitOptions:options prefixOptions:&prefixOptions queryOptions:&queryOptions];
		path = [self collectionPathWithPrefixOptions:prefixOptions queryOptions:queryOptions];
	}
	[self get:path completionHandler:^(NSHTTPURLResponse *HTTPResponse, id object, NSError *error) {
		if ([object isKindOfClass:[NSArray class]])
		{
			completionHandler([self instantiateCollection:object prefixOptions:prefixOptions], nil);
		}
		else
		{
			completionHandler(nil, [NSError errorWithDomain:ARErrorDomain code:ARUnsupportedRootObjectTypeError userInfo:nil]);
		}
	}];
}

- (NSArray *)instantiateCollection:(NSArray *)collection prefixOptions:(NSDictionary *)prefixOptions
{
	NSMutableArray *resources = [NSMutableArray array];
	for (NSDictionary *attributes in collection)
	{
		[resources addObject:[self instantiateRecordWithAttributes:attributes prefixOptions:prefixOptions]];
	}
	return [resources copy];
}

- (AResource *)instantiateRecordWithAttributes:(NSDictionary *)attributes prefixOptions:(NSDictionary *)prefixOptions
{
	Class klass = NSClassFromString(ASInflectorCamelize([self elementNameLazily], YES));
	if (klass == nil || ![klass isSubclassOfClass:[AResource class]])
	{
		klass = [AResource class];
	}
	AResource *resource = [[klass alloc] initWithBase:self attributes:attributes persisted:YES];
	[resource setPrefixOptions:prefixOptions];
	return resource;
}

- (NSSet *)prefixParameters
{
	NSMutableSet *parameters = [NSMutableSet set];
	NSString *prefixSource = [self prefixSourceLazily];
	for (NSTextCheckingResult *result in [[NSRegularExpression regularExpressionWithPattern:@":\\w+" options:0 error:NULL] matchesInString:prefixSource options:0 range:NSMakeRange(0, [prefixSource length])])
	{
		[parameters addObject:[[prefixSource substringWithRange:[result range]] substringFromIndex:1]];
	}
	return [parameters copy];
}

- (void)splitOptions:(NSDictionary *)options prefixOptions:(NSDictionary **)outPrefixOptions queryOptions:(NSDictionary **)outQueryOptions
{
	NSSet *prefixParameters = [self prefixParameters];
	NSMutableDictionary *prefixOptions = [NSMutableDictionary dictionary];
	NSMutableDictionary *queryOptions = [NSMutableDictionary dictionary];
	[options enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[[prefixParameters member:key] != nil ? prefixOptions : queryOptions setObject:obj forKey:key];
	}];
	if (outPrefixOptions)
	{
		*outPrefixOptions = [prefixOptions copy];
	}
	if (outQueryOptions)
	{
		*outQueryOptions = [queryOptions copy];
	}
}

//------------------------------------------------------------------------------
#pragma mark                                                       HTTP Requests
//------------------------------------------------------------------------------

// Under Rails, the HTTP request methods belong to a separate connection class,
// ActiveResource::Connection. That class acts as a shim in-between active
// resources and the Net::HTTP library, handling authentication and encryption
// if the connection requires such features. The Objective-C implementation
// obviates the connection class by delegating to the underlying Apple
// NSURLConnection implementation for the handling of authentication and
// encryption.

- (void)get:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:@"GET" path:path completionHandler:completionHandler];
}

- (void)delete:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:@"DELETE" path:path completionHandler:completionHandler];
}

- (void)put:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:@"PUT" path:path completionHandler:completionHandler];
}

- (void)post:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:@"POST" path:path completionHandler:completionHandler];
}

- (void)head:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:@"HEAD" path:path completionHandler:completionHandler];
}

- (void)requestHTTPMethod:(NSString *)HTTPMethod path:(NSString *)path completionHandler:(ARBaseRequestCompletionHandler)completionHandler
{
	NSURL *URL = [NSURL URLWithString:path relativeToURL:[self site]];
	ARConnection *connection = [[ARConnection alloc] initWithSite:URL format:[self formatLazily]];
	[connection setTimeout:[self timeout]];
	NSMutableURLRequest *request = [connection requestForHTTPMethod:HTTPMethod path:path headers:nil];
	
	ARURLConnectionDelegate *delegate = [[ARURLConnectionDelegate alloc] init];
	[delegate setCompletionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		if ([response isKindOfClass:[NSHTTPURLResponse class]])
		{
			NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
			// This method exists for two main purposes: (1) to cast the
			// generalised URL response to a protocol-specific HTTP response;
			// (2) to decode the body. Purpose number two presumes that all
			// responses require format-specific decoding. This seems like a
			// safe assumption, at present.
			if (data)
			{
				id object = [[self formatLazily] decode:data error:&error];
				if (object)
				{
					completionHandler(HTTPResponse, object, nil);
				}
				else
				{
					completionHandler(HTTPResponse, nil, error);
				}
			}
			else
			{
				completionHandler(HTTPResponse, nil, error);
			}
		}
		else
		{
			completionHandler(nil, nil, error ? error : [NSError errorWithDomain:ARErrorDomain code:ARResponseIsNotHTTPError userInfo:nil]);
		}
	}];
	NSURLConnection *HTTP = [connection HTTPWithRequest:request delegate:delegate];
	NSOperationQueue *operationQueue = [self operationQueue];
	if (operationQueue)
	{
		[HTTP setDelegateQueue:operationQueue];
	}
	[HTTP start];
}

@end

@implementation ARURLConnectionDelegate

@synthesize completionHandler = _completionHandler;
@synthesize response          = _response;
@synthesize data              = _data;

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return YES;
}

/*!
 * @brief Responds to authentication challenges.
 * @details The connection @em cannot continue without credentials in order to
 * access HTTPS resources. Creates a credential, passing it to the
 * authentication challenge's sender. Sends “server trust” provided by the
 * protection space of the authentication challenge.
 */
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
	NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
	[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[self setResponse:response];
	[self setData:[NSMutableData data]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[[self data] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self completionHandler]([self response], [[self data] copy], nil);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self completionHandler]([self response], nil, error);
}

@end
