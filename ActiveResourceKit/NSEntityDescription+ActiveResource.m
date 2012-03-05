// ActiveResourceKit NSEntityDescription+ActiveResource.m
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import "NSEntityDescription+ActiveResource.h"
#import "ARResource.h"

// for -[ASInflector underscore:camelCasedWord]
#import <ActiveSupportKit/ActiveSupportKit.h>

@implementation NSEntityDescription(ActiveResource)

- (NSDictionary *)attributesFromResource:(ARResource *)resource
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	NSDictionary *attributesByName = [self attributesByName];
	for (NSString *attributeName in attributesByName)
	{
		NSAttributeDescription *attribute = [attributesByName objectForKey:attributeName];
		id value = [resource valueForKey:attributeName];
		switch ([attribute attributeType])
		{
			case NSDateAttributeType:
				value = ASDateFromRFC3339String(value);
		}
		if (value)
		{
			[attributes setObject:value forKey:attributeName];
		}
	}
	return [attributes copy];
}

- (NSDictionary *)attributesFromObject:(NSManagedObject *)object
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	NSDictionary *attributesByName = [self attributesByName];
	for (NSString *attributeName in attributesByName)
	{
		NSAttributeDescription *attribute = [attributesByName objectForKey:attributeName];
		id value = [object valueForKey:attributeName];
		switch ([attribute attributeType])
		{
			case NSDateAttributeType:
				value = ASRFC3339StringFromDate(value);
		}
		if (value)
		{
			[attributes setObject:value forKey:[[ASInflector defaultInflector] underscore:attributeName]];
		}
	}
	return [attributes copy];
}

@end
