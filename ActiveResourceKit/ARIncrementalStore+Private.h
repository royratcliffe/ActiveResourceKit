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

//------------------------------------------- Active Resource-to-Core Data Names

// The following instance methods perform default name translations between
// Active Resource names and Core Data names. You might wish to override the
// following methods if your server-side and client-side element-entity names
// fall outside the simple underscored-to-camel case conversions and back.
//
// Separate method pairs exist for element-entity names and attribute-property
// names. The former translate between Active Resource elements and Core Data
// entities; the latter between Active Resource attributes and Core Data
// properties.

- (NSString *)elementNameForEntityName:(NSString *)entityName;
- (NSString *)entityNameForElementName:(NSString *)elementName;
- (NSString *)attributeNameForPropertyName:(NSString *)propertyName;
- (NSString *)propertyNameForAttributeName:(NSString *)attributeName;

@end
