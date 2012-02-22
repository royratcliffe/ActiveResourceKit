// ActiveResourceKit ARIncrementalStore.h
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

#import <CoreData/CoreData.h>

@class ARService;

/*!
 * @brief Core Data incremental store based on active resources.
 * @details The ARIncrementalStore class performs one simple function:
 * translating Core Data requests to Active Resource requests, and translating
 * Active Resource responses to Core Data responses. The class mediates between
 * Core Data and Active Resource. You can easily access remote resources using
 * Core Data by hooking up an ARIncrementStore-type store to your Core Data
 * context. Specify the site URL when you add the store. The store automatically
 * derives the resources and their properties using the managed-object model
 * along with standard Rails-compatible conventions for naming.
 */
@interface ARIncrementalStore : NSIncrementalStore
{
	// Use a cache for retaining child contexts by parent; iOS does not yet
	// support collections with zeroing weak references, e.g. hash tables. No
	// need to keep references to child contexts indefinitely. Recreate on
	// demand.
	NSCache *__strong _childContextsByParent;
	
	// Cache the resources by object ID. This cache associates Active Resource
	// with Core Data. It bridges the difference between the Active Resource
	// interface and the Core Data interface. When you "find" active resources,
	// all resource attributes become available. However, when Core Data fetches
	// managed objects incrementally, the incremental-store interface expects
	// only object IDs at first. Subsequently, Core Data asks for attribute and
	// relationship values. This cache exists to buffer those values until Core
	// Data requests them.
	//
	// Same goes when instantiating new object-resource pairs. The Active
	// Resource interface creates a new resource along with its attributes. Core
	// Data, however, only obtains permanent IDs initially. They become faulted
	// objects. Core Data asks for properties later when needed. Again, the
	// resources-by-object-ID cache acts as a bridging buffer.
	NSCache *__strong _resourcesByObjectID;
}

+ (NSString *)storeType;
+ (void)registerStoreClass;

/*!
 * @brief Derives a store's type for use when adding a store instance to your
 * persistent store coordinator.
 * @details You could define this explicitly but there exists an essential
 * requirement. It is very important that the store-type string matches the
 * class name. If not, your store will fail to successfully attach to its store
 * coordinator. Core Data's error reason explains, "The store type in the
 * metadata does not match the specified store type." Make them match to avoid
 * this error. Best way to make them match? Make store type equal to class name.
 */
+ (NSString *)storeTypeForClass:(Class)aClass;

/*!
 * @brief Registers an incremental store subclass.
 * @details You need to register the store class before using it. If your
 * run-time loading sequence prevents you registering the store type
 * automatically during class initialisation, that is, during @c +initialize,
 * then in such cases you need to invoke @c +registerStoreTypeForClass:aClass
 * explicitly @em before using the store type. Typically though, you can
 * register the store type during class initialisation. Your sub-class interface
 * will contain method declarations along these lines:
 * @code
 *	+ (NSString *)storeType;
 *	+ (void)registerStoreClass;
 * @endcode
 * Along with implementations as follows:
 * @code
 *	+ (void)initialize
 *	{
 *		if (self == [MyActiveResourceIncrementalStore class])
 *		{
 *			[self registerStoreClass];
 *		}
 *	}
 *
 *	+ (NSString *)storeType
 *	{
 *		return [ARIncrementalStore storeTypeForClass:self];
 *	}
 *
 *	+ (void)registerStoreClass
 *	{
 *		[ARIncrementalStore registerStoreTypeForClass:self];
 *	}
 * @endcode
 */
+ (void)registerStoreTypeForClass:(Class)aClass;

/*!
 * @brief Fetches or creates a managed object context attached as a child to the
 * given parent context.
 * @details The incremental store retains a cache of child contexts. If
 * necessary, the method forks a new private-queue concurrent context based on
 * the given context. Multiple contexts can exist for a single persistent-store
 * coordinator.
 */
- (NSManagedObjectContext *)childContextForParentContext:(NSManagedObjectContext *)parentContext;

/*!
 * @brief Answers a suitably-connected Active Resource service for interacting
 * with the given entity.
 * @details Performs Core Data entity-name to Active Resource element name
 * mapping. Uses a standard delegate-based URL connection. The connection runs
 * asynchronously but delegates synchronously and conveniently handles
 * authentication if needed.
 */
- (ARService *)serviceForEntityName:(NSString *)entityName;

- (id)executeFetchRequest:(NSFetchRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)outError;

- (id)executeSaveRequest:(NSSaveChangesRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)outError;

@end
