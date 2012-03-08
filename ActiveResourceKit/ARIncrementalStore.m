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
#import "NSEntityDescription+ActiveResource.h"

#import <ActiveSupportKit/ActiveSupportKit.h>

@interface ARIncrementalStore()

- (id)executeFetchRequest:(NSFetchRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError **)outError;

- (id)executeSaveRequest:(NSSaveChangesRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError **)outError;

@end

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
		_nodesByObjectID = [[NSMutableDictionary alloc] init];
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
- (BOOL)loadMetadata:(NSError **)outError
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

- (id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError **)outError
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
- (id)executeFetchRequest:(NSFetchRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError **)outError
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
	[[self serviceForEntityName:[request entityName]] findAllWithOptions:options completionHandler:^(ARHTTPResponse *response, NSArray *resources, NSError *error) {
		if (resources)
		{
			// Load up the resource cache first. Let new resources replace old
			// ones. The cache exists as a communication buffer between fetch
			// requests and other incremental-store interface methods. Do this
			// regardless of result type. It refreshes the cache with the latest
			// available resource attributes.
			NSMutableArray *nodes = [NSMutableArray array];
			for (ARResource *resource in resources)
			{
				NSManagedObjectID *objectID = [self newObjectIDForEntity:[request entity] referenceObject:[resource ID]];
				NSDictionary *values = [[objectID entity] attributesFromResource:resource];
				NSIncrementalStoreNode *node = [_nodesByObjectID objectForKey:objectID];
				if (node == nil)
				{
					node = [[NSIncrementalStoreNode alloc] initWithObjectID:objectID withValues:values version:0];
					[_nodesByObjectID setObject:node forKey:objectID];
				}
				else
				{
					[node updateWithValues:values version:[node version] + 1];
				}
				[nodes addObject:node];
			}
			
			// Compile the results for Core Data. Base the results on nodes,
			// rather than resources. Having previously iterated the resources
			// in order to create or update the incremental nodes, now deal with
			// the results in terms of managed objects and object IDs using
			// nodes.
			switch ([request resultType])
			{
				case NSManagedObjectResultType:
					result = [NSMutableArray array];
					for (NSIncrementalStoreNode *node in nodes)
					{
						// Tempting to load up the object attributes at this
						// point, right away. Do not however. Doing so triggers
						// the realisation of attributes before Core Data
						// expects.
						//
						//	[[context objectWithID:[node objectID]] loadAttributesFromResource:resource];
						//
						[(NSMutableArray *)result addObject:[context objectWithID:[node objectID]]];
					}
					result = [result copy];
					break;
				case NSManagedObjectIDResultType:
					result = [NSMutableArray array];
					for (NSIncrementalStoreNode *node in nodes)
					{
						[(NSMutableArray *)result addObject:[node objectID]];
					}
					result = [result copy];
					break;
				case NSCountResultType:
					result = [NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:[nodes count]]];
			}
		}
		else
		{
			// Relay the error. Note, this occurs here within a completion
			// block. Ensure that your original declaration for the error
			// pointer includes the __autoreleasing keyword, i.e.
			//
			//	NSError *__autoreleasing error = nil;
			//
			// Otherwise, you could encounter EXC_BAD_ACCESS aborts.
			if (outError && *outError == nil)
			{
				*outError = error;
			}
		}
	}];
	
	return result;
}

/*!
 * @brief Core Data sends this message when managed-object contexts save.
 * @details The save-changes request encapsulates inserted, updated and deleted
 * objects.
 */
- (id)executeSaveRequest:(NSSaveChangesRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError **)outError
{
	NSMutableArray *errors = [NSMutableArray array];
	for (NSManagedObject *object in [request insertedObjects])
	{
		;
	}
	for (NSManagedObject *object in [request updatedObjects])
	{
		// Updates occur by rebuilding the Active Resource from its associated
		// incremental node. You cannot assume that all the objects belong to
		// the same entity description. Likely, the set will include different
		// entities. Updating only occurs when saving the context. So updates
		// include all modified entities in-between save events.
		//
		// Save the resources one-by-one. This implies one connection for each
		// save operation. If there are many updates, could a bulk update
		// optimise the number of connections? Ideally, there should be one
		// create, one update and one delete request respectively containing all
		// the objects to insert, update and delete.
		NSEntityDescription *entity = [object entity];
		ARResource *resource = [[ARResource alloc] initWithService:[self serviceForEntityName:[entity name]]];
		[resource setValuesForKeysWithDictionary:[entity attributesFromObject:object]];
		[resource setPersisted:YES];
		[resource saveWithCompletionHandler:^(ARHTTPResponse *response, NSError *error) {
			if (error)
			{
				[errors addObject:error];
			}
		}];
	}
	for (NSManagedObject *object in [request deletedObjects])
	{
		NSNumber *ID = [self referenceObjectForObjectID:[object objectID]];
		NSEntityDescription *entity = [object entity];
		ARService *service = [self serviceForEntityName:[entity name]];
		[service deleteWithID:ID options:nil completionHandler:^(NSError *error) {
			if (error)
			{
				[errors addObject:error];
			}
		}];
	}
	BOOL success = [errors count] == 0;
	if (!success && outError && *outError == nil)
	{
		*outError = [errors objectAtIndex:0];
	}
	return success ? [NSArray array] : nil;
}

- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError **)outError
{
	return [_nodesByObjectID objectForKey:objectID];
}

- (id)newValueForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError **)outError
{
	return [super newValueForRelationship:relationship forObjectWithID:objectID withContext:context error:outError];
}

/*!
 * @details Invoked just before sending a save-changes request. Objects sent
 * here have only a temporary object ID. Objective: to assign permanent IDs to
 * newly inserted objects. Answers a set of matching object IDs. The
 * implementation assumes that the given object's have IDs always of nil. It
 * sends Active Resource "create with attributes" requests for each object in
 * order to obtain each object's permanent ID, as assigned by the resource
 * server.
 */
- (NSArray *)obtainPermanentIDsForObjects:(NSArray *)objects error:(NSError **)outError
{
	NSMutableArray *objectIDs = [NSMutableArray array];
	NSMutableArray *errors = [NSMutableArray array];
	for (NSManagedObject *object in objects)
	{
		NSEntityDescription *entity = [object entity];
		ARService *service = [self serviceForEntityName:[entity name]];
		[service createWithAttributes:[entity attributesFromObject:object] completionHandler:^(ARHTTPResponse *response, ARResource *resource, NSError *error) {
			if (resource)
			{
				NSManagedObjectID *objectID = [self newObjectIDForEntity:entity referenceObject:[resource ID]];
				NSDictionary *values = [[objectID entity] attributesFromResource:resource];
				[_nodesByObjectID setObject:[[NSIncrementalStoreNode alloc] initWithObjectID:objectID withValues:values version:0] forKey:objectID];
				[objectIDs addObject:objectID];
			}
			else
			{
				// Balance the object IDs against the objects. Resource creation
				// failure adds null to the resulting array. This is just a
				// token to assert this interface's object-to-object-ID mapping
				// principle.
				[objectIDs addObject:[NSNull null]];
				[errors addObject:error];
			}
		}];
	}
	BOOL success = [errors count] == 0;
	if (!success && outError && *outError == nil)
	{
		*outError = [errors objectAtIndex:0];
	}
	return success ? [objectIDs copy] : nil;
}

@end
