// ActiveResourceKit ARIncrementalStore+Private.h
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

#import <ActiveResourceKit/ARIncrementalStore.h>

@class ARResource;

@interface ARIncrementalStore(Private)

/**
 * Using a particular context, derives a managed-object identifier based
 * on a resource's element name and its primary key.
 *
 * Derives the entity name from the resource element name.
 */
- (NSManagedObjectID *)objectIDForResource:(ARResource *)resource withContext:(NSManagedObjectContext *)context;

/**
 * Answers the object identifier for a given resource after caching the
 * resource against its object identifier.
 */
- (NSManagedObjectID *)objectIDForCachedResource:(ARResource *)resource withContext:(NSManagedObjectContext *)context;

/**
 * Converts an object identifier to an active resource.
 *
 * The conversion occurs using the resource cache, if the resource
 * currently exists in the cache (a cache hit). Otherwise the implementation
 * first loads the cache with the resource using the given object identifier (a
 * cache miss). Uncached resources become cached before the method returns.
 */
- (ARResource *)cachedResourceForObjectID:(NSManagedObjectID *)objectID error:(NSError **)outError;

/**
 * Answers a 64-bit version number derived from the given `resource`.
 *
 * Uses the updated-at date-time as the version number. Converts the
 * update-at date to seconds since the reference date. This amounts to a big
 * version number, but the version number allows for 64 bits of unsigned integer
 * width.
 *
 * Also makes an assumption about the updated-at dates: that they always exceed
 * midnight 1st January 2001, the reference point. If they precede that point,
 * then the reference-relative time interval becomes negative, the signed
 * interval wraps the unsigned 64-bit version and version numbers start counting
 * down. This is not what Core Data will expect.
 *
 * The implementation multiplies the time interval by 1,000 in order to allow
 * for rare sub-second updates, if the server-side includes date-time at
 * sub-second resolutions. RFC 3339 date-time formats allow for sub-second
 * accuracy.
 */
- (uint64_t)versionForResource:(ARResource *)resource;

/**
 * Refreshes an object in the incremental store cache.
 * @param object The object to refresh.
 *
 * The given `object` disappears from the resource cache and becomes a
 * fault. Subsequent attempts to access the object will refetch its resource
 * attributes. This happens when objects insert. Inserted objects become
 * unrealised because the remote server typically validates and further updates
 * the inserted resource, e.g. by setting its update-at date. It also occurs
 * when you update an object, for the same reason. Object deletion also
 * refreshes the cache; the deleted resource disappears from the cache and the
 * object becomes a fault before disappearing from the managed-object context as
 * all deleted objects do.
 */
- (void)refreshObject:(NSManagedObject *)object;

/**
 * Resolves relationships.
 *
 * Picks out the to-one associations. Is there a foreign key with a
 * matching to-one relationship? Looks for a matching foreign key within the
 * resource for each to-one relationship. If the foreign key does not exist but
 * the to-one relationship does, then resolves the relationship at the server
 * side by assigning the foreign key to the relationship destination's object
 * reference, its resource identifier. Collects such foreign key attributes
 * first because there could be multiple. Merge and save them.
 *
 * Ignores to-many associations. Rails will handle that.
 */
- (NSDictionary *)foreignKeysForObject:(NSManagedObject *)object resource:(ARResource *)resource;

@end
