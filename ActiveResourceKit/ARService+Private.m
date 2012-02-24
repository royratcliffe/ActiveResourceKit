// ActiveResourceKit ARService+Private.m
//
// Copyright © 2011, 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import "ARService+Private.h"
#import "ARConnection.h"

#import <ActiveResourceKit/ActiveResourceKit.h>
#import <ActiveModelKit/ActiveModelKit.h>
#import <ActiveSupportKit/ActiveSupportKit.h>

NSString *const ARFromKey = @"from";
NSString *const ARParamsKey = @"params";

NSString *ARQueryStringForOptions(NSDictionary *options)
{
	return options == nil || [options count] == 0 ? @"" : [NSString stringWithFormat:@"?%@", [options toQueryWithNamespace:nil]];
}

@implementation ARService(Private)

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

- (void)findEveryWithOptions:(NSDictionary *)options completionHandler:(void (^)(ARHTTPResponse *response, NSArray *resources, NSError *error))completionHandler
{
	NSString *path;
	NSDictionary *prefixOptions;
	NSString *from = [options objectForKey:ARFromKey];
	if (from && [from isKindOfClass:[NSString class]])
	{
		prefixOptions = nil;
		path = [NSString stringWithFormat:@"%@%@", from, ARQueryStringForOptions([options objectForKey:ARParamsKey])];
	}
	else
	{
		NSDictionary *queryOptions = nil;
		[self splitOptions:options prefixOptions:&prefixOptions queryOptions:&queryOptions];
		path = [self collectionPathWithPrefixOptions:prefixOptions queryOptions:queryOptions];
	}
	[self get:path completionHandler:^(ARHTTPResponse *response, id object, NSError *error) {
		if ([object isKindOfClass:[NSArray class]])
		{
			completionHandler(response, [self instantiateCollection:object prefixOptions:prefixOptions], nil);
		}
		else
		{
			completionHandler(response, nil, [NSError errorWithDomain:ARErrorDomain code:ARUnsupportedRootObjectTypeError userInfo:nil]);
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

- (ARResource *)instantiateRecordWithAttributes:(NSDictionary *)attributes prefixOptions:(NSDictionary *)prefixOptions
{
	Class klass = NSClassFromString(ASInflectorCamelize([self elementNameLazily], YES));
	if (klass == nil || ![klass isSubclassOfClass:[ARResource class]])
	{
		klass = [ARResource class];
	}
	ARResource *resource = [[klass alloc] initWithService:self attributes:attributes persisted:YES];
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

- (void)get:(NSString *)path completionHandler:(ARServiceRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:ARHTTPGetMethod path:path body:nil completionHandler:completionHandler];
}

- (void)delete:(NSString *)path completionHandler:(ARServiceRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:ARHTTPDeleteMethod path:path body:nil completionHandler:completionHandler];
}

- (void)put:(NSString *)path body:(NSData *)data completionHandler:(ARServiceRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:ARHTTPPutMethod path:path body:data completionHandler:completionHandler];
}

- (void)post:(NSString *)path body:(NSData *)data completionHandler:(ARServiceRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:ARHTTPPostMethod path:path body:data completionHandler:completionHandler];
}

- (void)head:(NSString *)path completionHandler:(ARServiceRequestCompletionHandler)completionHandler
{
	[self requestHTTPMethod:ARHTTPHeadMethod path:path body:nil completionHandler:completionHandler];
}

- (void)requestHTTPMethod:(NSString *)HTTPMethod path:(NSString *)path body:(NSData *)data completionHandler:(ARServiceRequestCompletionHandler)completionHandler
{
	ARConnection *connection = [self connectionLazily];
	NSMutableURLRequest *request = [connection requestForHTTPMethod:HTTPMethod path:path headers:[[self headers] copy]];
	if (data)
	{
		[request setHTTPBody:data];
	}
	[connection sendRequest:request completionHandler:[self decodeHandlerWithCompletionHandler:completionHandler]];
}

- (ARConnectionCompletionHandler)decodeHandlerWithCompletionHandler:(ARServiceRequestCompletionHandler)completionHandler
{
	// This response handler exists for two main purposes: (1) to cast the
	// generalised URL response to a protocol-specific HTTP response; (2) to
	// decode the body. Purpose number two presumes that all responses arriving
	// here require format-specific decoding. If this is not true, do not use
	// this handler. Instead, roll your own.
	//
	// Sends -copy to the block thereby transferring the block from the local
	// stack to the heap. Copy for use after the destruction of this
	// scope. Compiling for iOS raises a warning unless you copy the block, but
	// not so for OS X.
	return [^(ARHTTPResponse *response, NSError *error) {
		if (response)
		{
			if ([response body])
			{
				error = [ARConnection errorForResponse:response];
				if (error == nil)
				{
					id object = [[self formatLazily] decode:data error:&error];
					if (object)
					{
						completionHandler(response, object, nil);
					}
					else
					{
						// decoding error
						completionHandler(response, nil, error);
					}
				}
				else
				{
					// response error
					completionHandler(response, nil, error);
				}
			}
			else
			{
				// connection error
				completionHandler(response, nil, error);
			}
		}
		else
		{
			// type error
			completionHandler(nil, nil, error ? error : [NSError errorWithDomain:ARErrorDomain code:ARResponseIsNotHTTPError userInfo:nil]);
		}
	} copy];
}

@end
