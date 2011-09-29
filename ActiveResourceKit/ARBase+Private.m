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
	return [[ASInflector defaultInflector] pluralize:[self elementName]];
}

- (NSString *)defaultPrefixSource
{
	return [[self site] path];
}

- (NSArray *)instantiateCollection:(NSArray *)collection prefixOptions:(NSDictionary *)prefixOptions
{
	NSMutableArray *resources = [NSMutableArray array];
	for (NSDictionary *attrs in collection)
	{
		[resources addObject:[self instantiateRecordWithAttributes:attrs prefixOptions:prefixOptions]];
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
	NSString *prefixSource = [self prefixSource];
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

- (void)get:(NSString *)path completionHandler:(void (^)(id object, NSError *error))completionHandler
{
	NSURL *URL = [NSURL URLWithString:path relativeToURL:[self site]];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:[self timeout]];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		if (data)
		{
			id object = [[self format] decode:data error:&error];
			if (object)
			{
				completionHandler(object, nil);
			}
			else
			{
				completionHandler(nil, error);
			}
		}
		else
		{
			completionHandler(nil, error);
		}
	}];
}

@end
