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
#import <ActiveSupportKit/ActiveSupportKit.h>

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

- (ARResource *)cachedResourceForObjectID:(NSManagedObjectID *)objectID error:(NSError **)outError
{
	ARResource *__block resource = [_resourcesByObjectID objectForKey:objectID];
	if (resource == nil)
	{
		NSNumber *ID = [self referenceObjectForObjectID:objectID];
		ARService *service = [self serviceForEntityName:[[objectID entity] name]];
		[service findSingleWithID:ID options:nil completionHandler:^(ARHTTPResponse *response, ARResource *aResource, NSError *error) {
			if (aResource)
			{
				[_resourcesByObjectID setObject:resource = aResource forKey:objectID];
			}
			else
			{
				if (outError && *outError == nil)
				{
					*outError = error;
				}
			}
		}];
	}
	return resource;
}

- (uint64_t)versionForResource:(ARResource *)resource
{
	uint64_t version;
	NSDate *updatedAt = ASDateFromRFC3339String(ASNilForNull([[resource attributes] objectForKey:@"updated_at"]));
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

- (void)refreshObject:(NSManagedObject *)object
{
	[_resourcesByObjectID removeObjectForKey:[object objectID]];
	[[object managedObjectContext] refreshObject:object mergeChanges:NO];
}

- (NSDictionary *)foreignKeysForObject:(NSManagedObject *)object resource:(ARResource *)resource
{
	NSMutableDictionary *foreignKeys = [NSMutableDictionary dictionary];
	for (NSPropertyDescription *property in [[object entity] properties])
	{
		if ([property isKindOfClass:[NSRelationshipDescription class]] && [(NSRelationshipDescription *)property maxCount] == 1)
		{
			NSString *attributeName = [self attributeNameForPropertyName:[(NSRelationshipDescription *)property name]];
			NSString *foreignKey = [[ASInflector defaultInflector] foreignKey:attributeName separateClassNameAndIDWithUnderscore:YES];
			NSManagedObject *destination = [object valueForKey:[(NSRelationshipDescription *)property name]];
			if (ASNilForNull([[resource attributes] objectForKey:foreignKey]) == nil && destination)
			{
				NSNumber *destinationID = [self referenceObjectForObjectID:[destination objectID]];
				[foreignKeys setObject:destinationID forKey:foreignKey];
			}
		}
	}
	return [foreignKeys copy];
}

@end
