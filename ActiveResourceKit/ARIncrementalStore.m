// ActiveResourceKit ARIncrementalStore.m
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

#import "ARIncrementalStore.h"
#import "ARResource.h"
#import "ARService.h"
#import "ARSynchronousLoadingURLConnection.h"
#import "NSManagedObject+ActiveResource.h"

#import <ActiveSupportKit/ActiveSupportKit.h>

@implementation ARIncrementalStore

+ (void)initialize
{
	if (self == [ARIncrementalStore class])
	{
		[self registerStoreClass];
	}
}

+ (NSString *)storeType
{
	return [ARIncrementalStore storeTypeForClass:self];
}

+ (void)registerStoreClass
{
	[ARIncrementalStore registerStoreTypeForClass:self];
}

+ (NSString *)storeTypeForClass:(Class)aClass
{
	return NSStringFromClass(aClass);
}

+ (void)registerStoreTypeForClass:(Class)aClass
{
	[NSPersistentStoreCoordinator registerStoreClass:aClass forStoreType:[self storeTypeForClass:aClass]];
}

// designated initialiser
- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root configurationName:(NSString *)name URL:(NSURL *)url options:(NSDictionary *)options
{
	self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:url options:options];
	if (self)
	{
		_childContextsByParent = [[NSCache alloc] init];
		_resourcesByObjectID = [[NSCache alloc] init];
	}
	return self;
}

- (NSManagedObjectContext *)childContextForParentContext:(NSManagedObjectContext *)parentContext
{
	NSManagedObjectContext *childContext = [_childContextsByParent objectForKey:parentContext];
	if (childContext == nil)
	{
		[childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] setParentContext:parentContext];
		[_childContextsByParent setObject:childContext forKey:parentContext];
	}
	return childContext;
}

- (ARService *)serviceForEntityName:(NSString *)entityName
{
	// The entity name may not correspond to a class name. You can use
	// managed-object entities even without deriving a sub-class. However, the
	// entity name follows class naming conventions: capitalised camel-case.
	ARService *service = [[ARService alloc] initWithSite:[self URL] elementName:[[ASInflector defaultInflector] underscore:entityName]];
	[service setConnection:[[ARSynchronousLoadingURLConnection alloc] init]];
	return service;
}

//------------------------------------------------------------------------------
#pragma mark                                  Incremental Store Method Overrides
//------------------------------------------------------------------------------

// The following methods appear in Core Data's public interface for
// NSIncrementalStore. Implementations below override the abstract interface
// laid out by Core Data.

/*!
 * @brief Validates the store URL.
 * @details Is the store URL usable? Does it exist? Can the store receive save
 * requests? Are the schemas compatible?
 */
- (BOOL)loadMetadata:(NSError *__autoreleasing *)outError
{
	NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
	[metadata setObject:[ARIncrementalStore storeTypeForClass:[self class]] forKey:NSStoreTypeKey];
	
	// Assigning a Universally-Unique ID is essential. Without this the next
	// invocation of -setMetadata: will recurse infinitely.
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	[metadata setObject:(__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid) forKey:NSStoreUUIDKey];
	CFRelease(uuid);
	
	[self setMetadata:[metadata copy]];
	return YES;
}

- (id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)outError
{
	switch ([request requestType])
	{
		case NSFetchRequestType:
			return [self executeFetchRequest:(NSFetchRequest *)request withContext:context error:outError];
		case NSSaveRequestType:
			return [self executeSaveRequest:(NSSaveChangesRequest *)request withContext:context error:outError];
	}
	return nil;
}

/*!
 * @result If the request is a fetch request whose result type is set to one of
 * @c NSManagedObjectResultType, @c NSManagedObjectIDResultType, @c
 * NSDictionaryResultType, returns an array containing all objects in the store
 * matching the request. If the request is a fetch request whose result type is
 * set to @c NSCountResultType, returns an array containing an @c NSNumber of
 * all objects in the store matching the request.
 *
 * This method runs on iOS, for instance, when a fetched results controller
 * performs a fetch in response to a table view controller determining the
 * number of sections in the table view.
 *
 * @par Fetch Request State
 * Executing a fetch request requires decoding the fetch request. Fetch requests
 * include numerous additional parameters, including:
 *
 *	- group-by properties
 *	- predicate
 *	- values to fetch
 *	- entity description
 *	- offset
 *	- sort descriptors
 *	- batch size
 *	- fetch limit
 *	- relationship key paths for pre-fetching
 *	- flags
 *
 * Requests can be complex. In Objective-C terms, you can acquire the full
 * fetch-request state using:
 * @code
 *	NSString *entityName = [request entityName];
 *	NSPredicate *predicate = [request predicate];
 *	NSArray *sortDescriptors = [request sortDescriptors];
 *	NSUInteger fetchLimit = [request fetchLimit];
 *	NSArray *affectedStores = [request affectedStores];
 *	NSFetchRequestResultType resultType = [request resultType];
 *	BOOL includesSubentities = [request includesSubentities];
 *	BOOL includesPropertyValues = [request includesPropertyValues];
 *	BOOL returnsObjectsAsFaults = [request returnsObjectsAsFaults];
 *	NSArray *relationshipKeyPathsForPrefetching = [request relationshipKeyPathsForPrefetching];
 *	BOOL includesPendingChanges = [request includesPendingChanges];
 *	BOOL returnsDistinctResults = [request returnsDistinctResults];
 *	NSArray *propertiesToFetch = [request propertiesToFetch];
 *	NSUInteger fetchOffset = [request fetchOffset];
 *	NSUInteger fetchBatchSize = [request fetchBatchSize];
 *	BOOL shouldRefreshRefetchedObjects = [request shouldRefreshRefetchedObjects];
 *	NSArray *propertiesToGroupBy = [request propertiesToGroupBy];
 *	NSPredicate *havingPredicate = [request havingPredicate];
 * @endcode
 */
- (id)executeFetchRequest:(NSFetchRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)outError
{
	id __block result = nil;
	
	NSMutableDictionary *options = [NSMutableDictionary dictionary];
	NSUInteger fetchLimit = [request fetchLimit];
	if (fetchLimit)
	{
		[options setValue:[NSNumber numberWithUnsignedInteger:fetchLimit] forKey:@"limit"];
	}
	NSUInteger fetchOffset = [request fetchOffset];
	if (fetchOffset)
	{
		[options setValue:[NSNumber numberWithUnsignedInteger:fetchOffset] forKey:@"offset"];
	}
	[[self serviceForEntityName:[request entityName]] findAllWithOptions:options completionHandler:^(NSHTTPURLResponse *HTTPResponse, NSArray *resources, NSError *error) {
		if (resources)
		{
			// Load up the resource cache first. Let new resources replace old
			// ones. The cache exists as a communication buffer between fetch
			// requests and other incremental-store interface methods. Do this
			// regardless of result type. It refreshes the cache with the latest
			// available resource attributes.
			for (ARResource *resource in resources)
			{
				[_resourcesByObjectID setObject:resource forKey:[self newObjectIDForEntity:[request entity] referenceObject:[resource ID]]];
			}
			
			switch ([request resultType])
			{
				case NSManagedObjectResultType:
					result = [NSMutableArray array];
					NSEntityDescription *entity = [NSEntityDescription entityForName:[request entityName] inManagedObjectContext:context];
					for (ARResource *resource in resources)
					{
						NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
						[object loadAttributesFromResource:resource];
						[result addObject:object];
					}
					result = [result copy];
					break;
				case NSCountResultType:
					result = [NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:[resources count]]];
			}
		}
		else
		{
			
		}
	}];
	
	return result;
}

- (id)executeSaveRequest:(NSSaveChangesRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)outError
{
	return [NSArray array];
}

@end
