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

/*!
 * @brief Using a particular context, derives a managed-object identifier based
 * on a resource's element name and its primary key.
 * @details Derives the entity name from the resource element name.
 */
- (NSManagedObjectID *)objectIDForResource:(ARResource *)resource withContext:(NSManagedObjectContext *)context;

/*!
 * @brief Answers the object identifier for a given resource after caching the
 * resource against its object identifier.
 */
- (NSManagedObjectID *)objectIDForCachedResource:(ARResource *)resource withContext:(NSManagedObjectContext *)context;

/*!
 * @brief Converts an object identifier to an active resource.
 * @details The conversion occurs using the resource cache, if the resource
 * currently exists in the cache (a cache hit). Otherwise the implementation
 * first loads the cache with the resource using the given object identifier (a
 * cache miss). Uncached resources become cached before the method returns.
 */
- (ARResource *)cachedResourceForObjectID:(NSManagedObjectID *)objectID error:(NSError **)outError;

/*!
 * @brief Answers a 64-bit version number derived from the given @a resource.
 * @details Uses the updated-at date-time as the version number. Converts the
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

@end
