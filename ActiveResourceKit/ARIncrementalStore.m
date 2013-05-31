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
#import "ARIncrementalStore+Private.h"
#import "ARResource.h"
#import "ARService.h"
#import "ARErrors.h"
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
- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)root configurationName:(NSString *)name URL:(NSURL *)URL options:(NSDictionary *)options
{
	self = [super initWithPersistentStoreCoordinator:root configurationName:name URL:URL options:options];
	if (self)
	{
		_resourcesByObjectID = [[NSCache alloc] init];
		[_resourcesByObjectID setDelegate:self];
		[self setEntityNamePrefix:[options objectForKey:ARIncrementalStoreElementNamePrefixKey]];
	}
	return self;
}

- (ARService *)serviceForEntityName:(NSString *)entityName
{
	// The entity name may not correspond to a class name. You can use
	// managed-object entities even without deriving a sub-class. However, the
	// entity name follows class naming conventions: capitalised camel-case.
	ARService *service = [[ARService alloc] initWithSite:[self URL] elementName:[self elementNameForEntityName:entityName]];
	[service setConnection:[[ARSynchronousLoadingURLConnection alloc] init]];
	return service;
}

- (void)evictAllResources
{
	[_resourcesByObjectID removeAllObjects];
}

//------------------------------------------------------------------------------
#pragma mark -                                Active Resource-to-Core Data Names
//------------------------------------------------------------------------------

@synthesize entityNamePrefix = _entityNamePrefix;

- (NSString *)elementNameForEntityName:(NSString *)entityName
{
	if ([self entityNamePrefix])
	{
		// The following implementation assumes that all entity names handled by
		// this incremental store have the given prefix. It removes the prefix
		// without first ensuring that the entity name begins with a matching
		// string; design by contract. If the assumption fails, your application
		// will throw an exception or otherwise fail.
		entityName = [entityName substringFromIndex:[[self entityNamePrefix] length]];
	}
	return [[ASInflector defaultInflector] underscore:entityName];
}

- (NSString *)entityNameForElementName:(NSString *)elementName
{
	NSString *entityName = [[ASInflector defaultInflector] camelize:elementName uppercaseFirstLetter:YES];
	if ([self entityNamePrefix])
	{
		entityName = [[self entityNamePrefix] stringByAppendingString:entityName];
	}
	return entityName;
}

- (NSString *)attributeNameForPropertyName:(NSString *)propertyName
{
	return [[ASInflector defaultInflector] underscore:propertyName];
}

- (NSString *)propertyNameForAttributeName:(NSString *)attributeName
{
	return [[ASInflector defaultInflector] camelize:attributeName uppercaseFirstLetter:NO];
}

//------------------------------------------------------------------------------
#pragma mark -                                Incremental Store Method Overrides
//------------------------------------------------------------------------------

// The following methods appear in Core Data's public interface for
// NSIncrementalStore. Implementations below override the abstract interface
// laid out by Core Data.

/**
 * Validates the store URL.
 *
 * Is the store URL usable? Does it exist? Can the store receive save
 * requests? Are the schemas compatible?
 */
- (BOOL)loadMetadata:(NSError **)outError
{
	NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
	[metadata setObject:[ARIncrementalStore storeTypeForClass:[self class]] forKey:NSStoreTypeKey];

	// Assigning a Universally-Unique ID is essential. Without this the next
	// invocation of -[setMetadata:] will recurse infinitely. Use the URL
	// description as the UUID. Within the context of Core Data, that should
	// provide a sufficiently unique identifier while giving the store's
	// managed-object IDs a meaningful and readable prefix.
	[metadata setObject:[[self URL] description] forKey:NSStoreUUIDKey];

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

/**
 * @result If the request is a fetch request whose result type is set to one of
 * `NSManagedObjectResultType`, `NSManagedObjectIDResultType`,
 * `NSDictionaryResultType`, returns an array containing all objects in the store
 * matching the request. If the request is a fetch request whose result type is
 * set to `NSCountResultType`, returns an array containing an `NSNumber` of
 * all objects in the store matching the request.
 *
 * This method runs on iOS, for instance, when a fetched results controller
 * performs a fetch in response to a table view controller determining the
 * number of sections in the table view.
 *
 * ### Fetch Request State
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
 *
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
	// Limit and offset only make sense for ordered resources. In fact, sort
	// descriptors are mandatory when using fetched results controllers. With no
	// sort descriptors, the controller throws an exception with reason, “An
	// instance of NSFetchedResultsController requires a fetch request with sort
	// descriptors.” The fetch request includes sort descriptors for this
	// reason. Core Data may present multiple sort descriptors. Use plus symbols
	// to separate sort keys followed by sort ascending or descending. Rails
	// converts the plus to space on the server. This makes an important
	// assumption about the server: that it responds correctly to the order
	// parameter. Typically, the Rails index action does not handle client-side
	// ordering requests. You can easily add the necessary ordering by adding
	// order(params[:order]) to the Active Record find all directive, e.g. if
	// your controller handles people then use the following statement to find
	// and order all the people.
	//
	//	@people = Person.order(params[:order]).all
	//
	// The order query reverts to default ordering when params[:order] is not
	// present, equals nil.
	//
	// Use property-to-attribute name mapping to derive the sort key. The sort
	// descriptor key exists in the Core Data namespace. However, the sort key
	// for the ordering parameter must cross the HTTP connection and interact
	// with the Rails namespace. The sort key follows property (Core Data)
	// conventions at this side of the connection, but follows attribute (Active
	// Resource) conventions at the far side of the connection.
	NSMutableArray *orderStrings = [NSMutableArray array];
	for (NSSortDescriptor *sortDescriptor in [request sortDescriptors])
	{
		[orderStrings addObject:[NSString stringWithFormat:@"%@+%@", [self attributeNameForPropertyName:[sortDescriptor key]], [sortDescriptor ascending] ? @"asc" : @"desc"]];
	}
	if ([orderStrings count])
	{
		[options setObject:[orderStrings componentsJoinedByString:@","] forKey:@"order"];
	}
	[[self serviceForEntityName:[request entityName]] findAllWithOptions:options completionHandler:^(ARHTTPResponse *response, NSArray *resources, NSError *error) {
		if (resources)
		{
			// Load up the resource cache first. Let new resources replace old
			// ones. The cache exists as a communication buffer between fetch
			// requests and other incremental-store interface methods. Do this
			// regardless of result type. It refreshes the cache with the latest
			// available resource attributes.
			NSMutableArray *objectIDs = [NSMutableArray array];
			for (ARResource *resource in resources)
			{
				[objectIDs addObject:[self objectIDForCachedResource:resource withContext:context]];
			}

			// Compile the results for Core Data. Having previously iterated the
			// resources in order to create or update the cache, now deal with
			// the results in terms of managed objects and object IDs.
			switch ([request resultType])
			{
				case NSManagedObjectResultType:
					result = [NSMutableArray array];
					for (NSManagedObjectID *objectID in objectIDs)
					{
						[(NSMutableArray *)result addObject:[context objectWithID:objectID]];
					}
					result = [result copy];
					break;
				case NSManagedObjectIDResultType:
					result = [NSMutableArray array];
					for (NSManagedObjectID *objectID in objectIDs)
					{
						[(NSMutableArray *)result addObject:objectID];
					}
					result = [result copy];
					break;
				case NSCountResultType:
					result = [NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:[objectIDs count]]];
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

/**
 * Core Data sends this message when managed-object contexts save.
 *
 * The save-changes request encapsulates inserted, updated and deleted
 * objects.
 */
- (id)executeSaveRequest:(NSSaveChangesRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError **)outError
{
	NSMutableArray *errors = [NSMutableArray array];

	// inserts
	//
	// Copy the insert-update-delete sets before iterating. This is necessary
	// because the inner loop refreshes the object. Core Data adjusts the given
	// sets when you refresh the object. Naughty, naughty. Apple documentation
	// does not mention this subtlety. Copying the set effectively side-steps
	// the collection mutation.
	//
	for (NSManagedObject *object in [[request insertedObjects] copy])
	{
		ARResource *resource = [self cachedResourceForObjectID:[object objectID] error:outError];
		if (resource)
		{
			NSDictionary *foreignKeys = [self foreignKeysForObject:object resource:resource];
			if ([foreignKeys count])
			{
				[resource mergeAttributes:foreignKeys];
				[resource saveWithCompletionHandler:^(ARHTTPResponse *response, NSError *error) {
					if (error == nil)
					{
						;
					}
					else
					{
						[errors addObject:error];
					}
				}];
			}
		}

		// There is a good reason for refreshing an inserted object, even though
		// at first sight reloading it appears odd. Are not the client and
		// server synchronised after a resource insertion with respect to the
		// inserted entities? No, because the server updates the created-at and
		// the updated-at time stamps. Accessing the object again therefore
		// requires a fetch in order to synchronise with the server. This
		// principle also applies to updates, see below.
		[self refreshObject:object];
	}

	// updates
	for (NSManagedObject *object in [[request updatedObjects] copy])
	{
		// Updates occur by rebuilding the Active Resource from its associated
		// incremental node unless the resource already exists in the cache. You
		// cannot assume that all the objects belong to the same entity
		// description. Likely, the set will include different
		// entities. Updating only occurs when saving the context. So updates
		// include all modified entities in-between save events.
		//
		// Save the resources one-by-one. This implies one connection for each
		// save operation. If there are many updates, could a bulk update
		// optimise the number of connections? Ideally, there should be one
		// create, one update and one delete request respectively containing all
		// the objects to insert, update and delete.
		NSEntityDescription *entity = [object entity];
		ARResource *resource = [_resourcesByObjectID objectForKey:[object objectID]];
		if (resource == nil)
		{
			resource = [[ARResource alloc] initWithService:[self serviceForEntityName:[entity name]]];
		}
		// Optimise PUT requests. Extract updated attributes from the managed
		// object. Merge these with foreign-key updates. However, if the
		// resulting merge exactly matches the cached resource attributes, then
		// skip the resource save operation, as an optimisation. Do not compare
		// attributes only appearing in the cached resource when finding
		// differences; attributes only appearing in the resource cache have
		// never been accessed or modified, likely because the client-side data
		// model does not describe these ignored attributes. This makes an
		// important assumption: that the resource always reflects its
		// server-side state. The assumption remains true because the
		// incremental store flushes the resource on insert, update and
		// delete. Anything remaining in the cache was fetched from the server
		// and therefore remains in-sync with the server until modified or
		// deleted.
		NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[entity attributesFromObject:object]];
		[attributes setValuesForKeysWithDictionary:[self foreignKeysForObject:object resource:resource]];
		if ([attributes isEqualToDictionary:[[resource attributes] dictionaryWithValuesForKeys:[attributes allKeys]]])
		{
			continue;
		}
		[resource mergeAttributes:attributes];
		[resource setPersisted:YES];
		[resource saveWithCompletionHandler:^(ARHTTPResponse *response, NSError *error) {
			if (error == nil)
			{
				[self refreshObject:object];
			}
			else
			{
				[errors addObject:error];
			}
		}];
	}

	// deletes
	for (NSManagedObject *object in [[request deletedObjects] copy])
	{
		NSNumber *ID = [self referenceObjectForObjectID:[object objectID]];
		NSEntityDescription *entity = [object entity];
		ARService *service = [self serviceForEntityName:[entity name]];
		[service deleteWithID:ID options:nil completionHandler:^(ARHTTPResponse *response, NSError *error) {
			if (error == nil)
			{
				[self refreshObject:object];
			}
			else
			{
				[errors addObject:error];
			}
		}];
	}

	// results
	BOOL success = [errors count] == 0;
	if (!success && outError && *outError == nil)
	{
		*outError = [errors objectAtIndex:0];
	}
	return success ? [NSArray array] : nil;
}

- (NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError **)outError
{
	// If not already in the cache, turn the fault into a resource.
	ARResource *resource = [self cachedResourceForObjectID:objectID error:outError];

	NSIncrementalStoreNode *node;
	if (resource)
	{
		// Do not reflect null-valued properties in the snapshot. Take
		// properties from the remote resource, find which if any have null
		// values, then remove those key-value pairs. Core Data interprets
		// missing attributes which appear in the data model as nils. Therefore
		// missing equals nil and hence null equals nil, when
		// missing. Otherwise, Core Data sends messages to the non-nil values,
		// e.g. sends -length to string-type attributes; this raises an
		// exception of course if the string equals [NSNull null] and not nil.
		NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:[[objectID entity] propertiesFromResource:resource]];
		[properties removeObjectsForKeys:[properties allKeysForObject:[NSNull null]]];
		uint64_t version = [self versionForResource:resource];
		node = [[NSIncrementalStoreNode alloc] initWithObjectID:objectID withValues:[properties copy] version:version];
	}
	else
	{
		node = nil;
		if (outError && *outError == nil)
		{
			*outError = [NSError errorWithDomain:ARErrorDomain code:ARValuesForObjectError userInfo:nil];
		}
	}
	return node;
}

- (id)newValueForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError **)outError
{
	id __block result;
	// to-one
	if ([relationship maxCount] == 1)
	{
		// Active resources implement to-one associations using foreign keys,
		// meaning the incremental store expects the remote server to provide a
		// "relationship_id" attribute for each to-one resource at the origin
		// of the to-one association.
		//
		// Back references are a special case. Their identifiers do not exist
		// within the resource attributes. Active Resource Kit splits off the
		// identifier from the attributes for nested resources. The
		// back-referencing identifier lives instead within the prefix
		// options. Hence, resolve the relationship by looking first in the
		// attributes; but then by looking if necessary in the prefix options.
		ARResource *resource = [_resourcesByObjectID objectForKey:objectID];
		NSString *relationshipName = [self attributeNameForPropertyName:[relationship name]];
		NSString *foreignKey = [[ASInflector defaultInflector] foreignKey:relationshipName separateClassNameAndIDWithUnderscore:YES];
		id foreignID = ASNilForNull([[resource attributes] objectForKey:foreignKey]);
		if (foreignID == nil)
		{
			foreignID = [[resource prefixOptions] objectForKey:foreignKey];
		}
		if (foreignID == nil)
		{
			result = [NSNull null];
		}
		else
		{
			result = [self newObjectIDForEntity:[relationship destinationEntity] referenceObject:foreignID];
		}
	}
	// to-many
	else if ([relationship isToMany])
	{
		// Answer an array of managed-object identifiers. Using standard RESTful
		// approaches, no interface exists for querying just the resource
		// identifiers. Instead, ask for the resources entirely, all attributes
		// included. Rely on the resource cache to save the attributes for later
		// when the object identifiers change from faults to realised objects.
		//
		// At present, the nested service cannot appear in the cache because the
		// cache indexes by entity name; nor would it be correct to cache by the
		// destination entity name, because the nested resource may not
		// correspond to the non-nested resource by the same name. Caching would
		// be possible in future if the cache indexed by site path.
		//
		// Derive the resource identifier from the object identifier. Hence, the
		// actual resource does not need to exist in the cache. If it does not
		// exist, there is no need to load it, an optimisation.
		ARService *service = [self serviceForEntityName:[[objectID entity] name]];
		ARService *nestedService = [[ARService alloc] initWithSite:[service siteWithPrefixParameter]];
		[nestedService setElementName:[[ASInflector defaultInflector] singularize:[relationship name]]];
		[nestedService setConnection:[[ARSynchronousLoadingURLConnection alloc] init]];
		NSDictionary *options = [NSDictionary dictionaryWithObject:[self referenceObjectForObjectID:objectID] forKey:[service foreignKey]];
		[nestedService findAllWithOptions:options completionHandler:^(ARHTTPResponse *response, NSArray *resources, NSError *error) {
			if (resources)
			{
				NSMutableArray *objectIDs = [NSMutableArray array];
				for (ARResource *resource in resources)
				{
					[objectIDs addObject:[self objectIDForCachedResource:resource withContext:context]];
				}
				result = [objectIDs copy];
			}
			else
			{
				result = nil;
				if (outError && *outError == nil)
				{
					*outError = error;
				}
			}
		}];
	}
	else
	{
		result = nil;
		if (outError && *outError == nil)
		{
			*outError = [NSError errorWithDomain:ARErrorDomain code:ARValueForRelationshipError userInfo:nil];
		}
	}
	return result;
}

/**
 * Invoked just before sending a save-changes request. Objects sent
 * here have only a temporary object ID. Objective: to assign permanent IDs to
 * newly inserted objects. Answers a set of matching object IDs. The
 * implementation assumes that the given object's have IDs always of nil. It
 * sends Active Resource "create with attributes" requests for each object in
 * order to obtain each object's permanent ID, as assigned by the resource
 * server.
 *
 * There is a synchronisation issue here. The given objects do not yet exist at
 * the server side; they have no permanent identifiers and hence Core Data asks
 * for those identifiers by invoking this override. The objects need
 * creating. Their permanent identifiers appear at the server side when the
 * remote application creates the associated record.
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
				[_resourcesByObjectID setObject:resource forKey:objectID];
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

- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{

}

@end

NSString *ARIncrementalStoreElementNamePrefixKey = @"ARIncrementalStoreElementNamePrefix";
