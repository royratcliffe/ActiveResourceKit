// ActiveResourceKit NSEntityDescription+ActiveResource.h
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

#import <CoreData/CoreData.h>

@class ARResource;

@interface NSEntityDescription(ActiveResource)

/*!
 * @brief Derives attributes from a given resource using this entity
 * description's attributes.
 * @details Performs date conversions, using the managed object's entity
 * description to discover attributes. This approach makes an important
 * assumption: that your managed-object model represents the Active Resource
 * schema, or at least part of the schema. There is only one difference: naming
 * convention. The Core Data schema uses camel-case; the resource schema uses
 * underscored names. This method does not validate the schema however. It
 * silently ignores resource attributes that do not appear in the managed-object
 * model.
 *
 * The method does not handle relationships, only attributes. At this point in
 * the class hierarchy, the method cannot resolve relationships. Resolution
 * requires assumptions about how Core Data relations map to Active Resource
 * relations, and vice versa. Typically this occurs by accessing the foreign key
 * for to-one associations or accessing resources at a remove sub-path in the
 * case of to-many associations. Either way, such mapping must assume things
 * about the Core Data and Active Resource idioms and their interaction.
 */
- (NSDictionary *)attributesFromResource:(ARResource *)resource;

/*!
 * @brief Answers a dictionary of Active Resource-style attributes derived from
 * the given managed object.
 * @details Performs reverse-date conversions: from @c NSDate to RFC
 * 3339-formatted strings suitable for Rails applications. The method iterates
 * through all attributes, attributes only, no relationships. The implementation
 * uses Key-Value Coding to access the given managed object. For date
 * attributes, it converts from @c NSDate to RFC 3339 date-time strings. The
 * resulting dictionary of attributes keys by Rails-convention attribute names,
 * i.e. underscored keys rather than camel-cased keys. Use the results for
 * Active Resource attributes, not for Core Data attributes.
 */
- (NSDictionary *)attributesFromObject:(NSManagedObject *)object;

@end
