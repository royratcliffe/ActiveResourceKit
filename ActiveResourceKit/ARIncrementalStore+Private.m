// ActiveResourceKit ARIncrementalStore+Private.m
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

#import "ARIncrementalStore+Private.h"

#import <ActiveResourceKit/ActiveResourceKit.h>

@implementation ARIncrementalStore(Private)

- (NSManagedObjectID *)objectIDForResource:(ARResource *)resource withContext:(NSManagedObjectContext *)context
{
	NSString *entityName = [self entityNameForElementName:[[resource serviceLazily] elementNameLazily]];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	return [self newObjectIDForEntity:entity referenceObject:[resource ID]];
}

- (NSManagedObjectID *)objectIDForCachedResource:(ARResource *)resource withContext:(NSManagedObjectContext *)context
{
	NSManagedObjectID *objectID = [self objectIDForResource:resource withContext:context];
	[_resourcesByObjectID setObject:resource forKey:objectID];
	return objectID;
}

- (uint64_t)versionForResource:(ARResource *)resource
{
	uint64_t version;
	NSDate *updatedAt = [[resource attributes] objectForKey:@"updated_at"];
	if (updatedAt)
	{
		version = [updatedAt timeIntervalSinceReferenceDate] * 1000;
	}
	else
	{
		version = 0;
	}
	return version;
}

@end
