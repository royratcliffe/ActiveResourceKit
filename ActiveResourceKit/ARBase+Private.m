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

#import <ActiveResourceKit/ActiveResourceKit.h>
#import <ActiveModelKit/ActiveModelKit.h>
#import <ActiveSupportKit/ActiveSupportKit.h>

NSString *const kARFromKey = @"from";
NSString *const kARParamsKey = @"params";

NSString *ARQueryStringForOptions(NSDictionary *options)
{
	return options == nil || [options count] == 0 ? @"" : [NSString stringWithFormat:@"?%@", [options toQueryWithNamespace:nil]];
}

@implementation ARBase(Private)

- (id<ARFormat>)defaultFormat
{
	return [ARJSONFormat JSONFormat];
}

- (NSString *)defaultElementName
{
	return [[[[AMName alloc] initWithClass:[self class]] autorelease] element];
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
	return [[resources copy] autorelease];
}

- (AResource *)instantiateRecordWithAttributes:(NSDictionary *)attributes prefixOptions:(NSDictionary *)prefixOptions
{
	AResource *resource = [[[AResource alloc] initWithBase:self attributes:attributes persisted:YES] autorelease];
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
	return [[parameters copy] autorelease];
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
		*outPrefixOptions = [[prefixOptions copy] autorelease];
	}
	if (outQueryOptions)
	{
		*outQueryOptions = [[queryOptions copy] autorelease];
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

- (void)get:(NSString *)path completionHandler:(void (^)(NSHTTPURLResponse *HTTPResponse, id object, NSError *error))completionHandler
{
	[self requestHTTPMethod:@"GET" path:path completionHandler:completionHandler];
}

- (void)delete:(NSString *)path completionHandler:(void (^)(NSHTTPURLResponse *HTTPResponse, id object, NSError *error))completionHandler
{
	[self requestHTTPMethod:@"DELETE" path:path completionHandler:completionHandler];
}

- (void)put:(NSString *)path completionHandler:(void (^)(NSHTTPURLResponse *HTTPResponse, id object, NSError *error))completionHandler
{
	[self requestHTTPMethod:@"PUT" path:path completionHandler:completionHandler];
}

- (void)post:(NSString *)path completionHandler:(void (^)(NSHTTPURLResponse *HTTPResponse, id object, NSError *error))completionHandler
{
	[self requestHTTPMethod:@"POST" path:path completionHandler:completionHandler];
}

- (void)head:(NSString *)path completionHandler:(void (^)(NSHTTPURLResponse *HTTPResponse, id object, NSError *error))completionHandler
{
	[self requestHTTPMethod:@"HEAD" path:path completionHandler:completionHandler];
}

- (void)requestHTTPMethod:(NSString *)HTTPMethod path:(NSString *)path completionHandler:(void (^)(NSHTTPURLResponse *HTTPResponse, id object, NSError *error))completionHandler
{
	NSURL *URL = [NSURL URLWithString:path relativeToURL:[self site]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:[self timeout]];
	NSMutableDictionary *headerFields = [NSMutableDictionary dictionaryWithDictionary:[request allHTTPHeaderFields]];
	[headerFields addEntriesFromDictionary:[self HTTPFormatHeaderForHTTPMethod:HTTPMethod]];
	[request setAllHTTPHeaderFields:headerFields];
	[request setHTTPMethod:HTTPMethod];
	
	NSOperationQueue *operationQueue = [self operationQueue];
	if (operationQueue == nil) operationQueue = [NSOperationQueue currentQueue];
	[NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
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
}

//------------------------------------------------------------------------------
#pragma mark                                            Format Header for Method
//------------------------------------------------------------------------------

- (NSDictionary *)HTTPFormatHeaderForHTTPMethod:(NSString *)HTTPMethod
{
	static struct
	{
		NSString *const HTTPMethod;
		NSString *const headerName;
	}
	const HTTPFormatHeaderNames[] =
	{
		{ @"GET",    @"Accept" },
		{ @"PUT",    @"Content-Type" },
		{ @"POST",   @"Content-Type" },
		{ @"DELETE", @"Accept" },
		{ @"HEAD",   @"Accept" },
	};
#define DIMOF(array) (sizeof(array)/sizeof((array)[0]))
	// Is this too ugly? A dictionary could implement the look-up. But that
	// requires building a static dictionary initially and does not allow
	// optimisation of searching. Using a simple linear look-up speeds up the
	// more common request types, i.e. GET requests. There is a cost, that of
	// slower look-up for less common types, e.g. HEAD. Is this a reasonable
	// trade-off?
	NSUInteger index;
	for (index = 0; index < DIMOF(HTTPFormatHeaderNames); index++)
	{
		if ([HTTPMethod isEqualToString:HTTPFormatHeaderNames[index].HTTPMethod])
		{
			break;
		}
	}
	NSDictionary *formatHeader;
	if (index < DIMOF(HTTPFormatHeaderNames))
	{
		formatHeader = [NSDictionary dictionaryWithObject:[[self formatLazily] MIMEType] forKey:HTTPFormatHeaderNames[index].headerName];
	}
	else
	{
		formatHeader = [NSDictionary dictionary];
	}
	return formatHeader;
}

@end
