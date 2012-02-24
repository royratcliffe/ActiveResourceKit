// ActiveResourceKit ARResource+Private.m
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

#import "ARResource+Private.h"
#import "ARService+Private.h"
#import "ARHTTPResponse.h"
#import "ARErrors.h"

NSNumber *ARIDFromResponse(ARHTTPResponse *response)
{
	NSString *location = [[response headerFields] objectForKey:@"Location"];
	if (location == nil)
	{
		return nil;
	}
	NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"\\/([^\\/]*?)(\\.\\w+)?$" options:0 error:NULL];
	NSTextCheckingResult *match = [re firstMatchInString:location options:0 range:NSMakeRange(0, [location length])];
	if (match == nil || [match numberOfRanges] < 2)
	{
		return nil;
	}
	NSString *string = [location substringWithRange:[match rangeAtIndex:1]];
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	return [numberFormatter numberFromString:string];
}

BOOL ARResponseCodeAllowsBody(NSInteger code)
{
	return !((100 <= code && code <= 199) || code == 204 || code == 304);
}

@implementation ARResource(Private)

- (void)updateWithCompletionHandler:(void (^)(ARHTTPResponse *response, NSError *error))completionHandler
{
	NSString *path = [[self serviceLazily] elementPathForID:[self ID] prefixOptions:[self prefixOptions] queryOptions:nil];
	[[self serviceLazily] put:path body:[self encode] completionHandler:^(ARHTTPResponse *response, id attributes, NSError *error) {
		if (attributes)
		{
			if ([attributes isKindOfClass:[NSDictionary class]])
			{
				[self loadAttributesFromResponse:response attributes:attributes];
				completionHandler(response, nil);
			}
			else
			{
				completionHandler(response, [NSError errorWithDomain:ARErrorDomain code:ARUnsupportedRootObjectTypeError userInfo:nil]);
			}
		}
		else
		{
			completionHandler(response, error);
		}
	}];
}

- (void)createWithCompletionHandler:(void (^)(ARHTTPResponse *response, NSError *error))completionHandler
{
	NSString *path = [[self serviceLazily] collectionPathWithPrefixOptions:nil queryOptions:nil];
	[[self serviceLazily] post:path body:[self encode] completionHandler:^(ARHTTPResponse *response, id attributes, NSError *error) {
		if (attributes)
		{
			if ([attributes isKindOfClass:[NSDictionary class]])
			{
				[self setID:ARIDFromResponse(response)];
				[self loadAttributesFromResponse:response attributes:attributes];
				completionHandler(response, nil);
			}
			else
			{
				completionHandler(response, [NSError errorWithDomain:ARErrorDomain code:ARUnsupportedRootObjectTypeError userInfo:nil]);
			}
		}
		else
		{
			completionHandler(response, error);
		}
	}];
}

- (void)loadAttributesFromResponse:(ARHTTPResponse *)response attributes:(NSDictionary *)attributes
{
	NSDictionary *headerFields;
	NSString *contentLength;
	
	if (ARResponseCodeAllowsBody([response code]) &&
		((contentLength = [headerFields = [response headerFields] objectForKey:@"Content-Length"]) == nil || ![contentLength isEqualToString:@"0"]))
	{
		[self loadAttributes:attributes removeRoot:YES];
		[self setPersisted:YES];
	}
}

@end
