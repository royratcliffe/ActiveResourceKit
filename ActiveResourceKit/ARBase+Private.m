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
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:[self timeout]];
	NSMutableDictionary *headerFields = [NSMutableDictionary dictionaryWithDictionary:[request allHTTPHeaderFields]];
	[headerFields addEntriesFromDictionary:[self HTTPFormatHeaderForHTTPMethod:HTTPMethod]];
	[request setAllHTTPHeaderFields:headerFields];
	[request setHTTPMethod:HTTPMethod];
	
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
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:delegate];
	NSOperationQueue *operationQueue = [self operationQueue];
	if (operationQueue)
	{
		[connection setDelegateQueue:operationQueue];
	}
	[connection start];
}

//------------------------------------------------------------------------------
#pragma mark                                            Format Header for Method
//------------------------------------------------------------------------------

/*!
 * @param array A standard C array of fixed-sized elements.
 * @brief Answers the number of elements in the given array, the array's dimension.
 * @details Assumes that the array argument is a standard C-style array where
 * the compiler can assess the number of elements by dividing the size of the
 * entire array by the size of its elements; the answer always equals an integer
 * since array size is a multiple of element size. Both measurements must be
 * static, otherwise the compiler cannot supply a fixed integer dimension.  The
 * implementation wraps the argument in parenthesis in order to enforce the
 * necessary operator precedence.
 * @note Beware of side effects if you pass operators in the @a array
 * expression. The macro argument evaluates twice.
 */
#define DIMOF(array) (sizeof(array)/sizeof((array)[0]))

- (NSDictionary *)HTTPFormatHeaderForHTTPMethod:(NSString *)HTTPMethod
{
	// Use CFStringRefs rather than NSString pointers when using Automatic
	// Reference Counting. ARC does not allow references within C
	// structures. Toll-free bridging exists between Core Foundation and Next
	// Step strings.
	static struct
	{
		CFStringRef const HTTPMethod;
		CFStringRef const headerName;
	}
	const HTTPFormatHeaderNames[] =
	{
		{ CFSTR("GET"),    CFSTR("Accept") },
		{ CFSTR("PUT"),    CFSTR("Content-Type") },
		{ CFSTR("POST"),   CFSTR("Content-Type") },
		{ CFSTR("DELETE"), CFSTR("Accept") },
		{ CFSTR("HEAD"),   CFSTR("Accept") },
	};
	// Is this too ugly? A dictionary could implement the look-up. But that
	// requires building a static dictionary initially and does not allow
	// optimisation of searching. Using a simple linear look-up speeds up the
	// more common request types, i.e. GET requests. There is a cost, that of
	// slower look-up for less common types, e.g. HEAD. Is this a reasonable
	// trade-off?
	NSUInteger index;
	for (index = 0; index < DIMOF(HTTPFormatHeaderNames); index++)
	{
		if ([HTTPMethod isEqualToString:(__bridge NSString *)HTTPFormatHeaderNames[index].HTTPMethod])
		{
			break;
		}
	}
	NSDictionary *formatHeader;
	if (index < DIMOF(HTTPFormatHeaderNames))
	{
		formatHeader = [NSDictionary dictionaryWithObject:[[self formatLazily] MIMEType] forKey:(__bridge NSString *)HTTPFormatHeaderNames[index].headerName];
	}
	else
	{
		formatHeader = [NSDictionary dictionary];
	}
	return formatHeader;
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

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
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
