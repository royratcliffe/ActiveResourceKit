// ActiveResourceKit ARResource.h
//
// Copyright © 2011, 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import <Foundation/Foundation.h>
#import <ActiveModelKit/ActiveModelKit.h>

@class ARService;
@class ARHTTPResponse;

/*!
 * @brief Provides the core class mirroring Rails' @c ActiveResource::Base class.
 * @details An active resource mimics an active record. Resources behave as
 * records. Only their connection fundamentally differs. Active Records connect
 * to a database whereas Active Resources connect to a RESTful API accessed via
 * HTTP transport.
 *
 * @image html Class_Diagram__Service_and_Resource.png
 */
@interface ARResource : NSObject<AMAttributeMethods, NSCopying>

/*!
 * @brief Constructs an active resource service using class methods to establish
 * the site and element name.
 * @details If the ARResource sub-class has a class method called +site, use its
 * answer to set up the Active Resource site. This assumes that +site answers an
 * NSURL object. Similarly, sets up the service element name by sending
 * +elementName to the sub-class, answering a string. However, if the sub-class
 * does not implement the +elementName class method, the element name derives
 * from the ARResource sub-class name.
 */
+ (ARService *)service;

- (id)initWithService:(ARService *)service;

- (id)initWithService:(ARService *)service attributes:(NSDictionary *)attributes;

- (id)initWithService:(ARService *)service attributes:(NSDictionary *)attributes persisted:(BOOL)persisted;

//------------------------------------------------------------------------- Base

/*!
 * Retains the active-resource service. Does not copy the service. This has important
 * implications. If you alter service properties, the changes affect all the
 * resources which depend upon it.
 */
@property(strong, NS_NONATOMIC_IOSONLY) ARService *service;

/*!
 * @brief Asks for the resource service, lazily constructing a service instance if the
 * resource does not currently retain a service.
 * @details Asks the class for a site URL and an element name. Optionally
 * implement @c +site and @c +elementName to supply the URL and element name. If
 * your class does not supply an implementation for @c +elementName, the element
 * name derives from the sub-class name. This assumes that you do not directly
 * instantiate the ARResource class. If you do, the element name remains @c nil.
 */
- (ARService *)serviceLazily;

//------------------------------------------------------------------- Attributes

@property(copy, NS_NONATOMIC_IOSONLY) NSDictionary *attributes;

/*!
 * @brief Merges the contents of a dictionary into the receiver's attributes.
 * @param attributes The dictionary (or hash) of attribute key-value pairs used
 * for merging with the receiver's attributes.
 * @details If keys within the given dictionary of @a attributes match keys in
 * the receiver's current attributes, merging replaces the objects in the
 * receiver by those in the given dictionary.
 */
- (void)mergeAttributes:(NSDictionary *)attributes;

/*!
 * @brief Loads resource attributes from a dictionary of key-value pairs.
 * @details Argument @a removeRoot becomes a do-not-care if @a attributes
 * contains just a single key-object pair. In such a case, removing the root
 * depends on whether or not the single key matches the service element name.
 *
 * Attribute keys use Rails conventions: underscored and lower case. You can
 * also access the attribute values using Key-Value Coding where the keys follow
 * Cocoa conventions: camel case with leading lower case letter. The resource
 * translates the KVC-style keys to Rails conventions when looking up the
 * corresponding value, @c aKey becomes @c a_key.
 */
- (void)loadAttributes:(NSDictionary *)attributes removeRoot:(BOOL)removeRoot;

//--------------------------------------------------------------- Prefix Options

@property(copy, NS_NONATOMIC_IOSONLY) NSDictionary *prefixOptions;

//-------------------------------------------------- Schema and Known Attributes

- (NSDictionary *)schema;

/*!
 * @brief Answers all the known attributes belonging to this active resource, a
 * unique array of attribute key strings.
 * @details The resulting array includes all the service's known attributes plus
 * this resource instance's known attributes. Duplicates if any do @e not
 * appear. This deviates from Rails at version 3.1.0 where duplicates @e do
 * appear.
 */
- (NSArray *)knownAttributes;

//-------------------------------------------------------------------- Persisted

@property(assign, NS_NONATOMIC_IOSONLY) BOOL persisted;

- (BOOL)isNew;
- (BOOL)isNewRecord;

//------------------------------------------------------------------ Primary Key

/*!
 * @brief Answers the primary key.
 * @details By convention, Rails' primary keys appear in the column named @c
 * id. Column type is integer. Hence the ActiveResourceKit implementation
 * answers the primary key only if the type is a number. (This includes other
 * types of number.) Otherwise it answers @c nil.
 * @par Integer Width
 * The exact integer type depends on the database implementation and
 * configuration at the server side. Databases typically store integers as
 * signed 32-bit integers. Send -[NSNumber intValue] to the resulting number to
 * retrieve the signed 32-bit identifier in such cases.
 */
- (NSNumber *)ID;

- (void)setID:(NSNumber *)ID;

//------------------------------------------------------------- RESTful Services

- (void)saveWithCompletionHandler:(void (^)(ARHTTPResponse *response, NSError *error))completionHandler;

- (void)existsWithCompletionHandler:(void (^)(ARHTTPResponse *response, BOOL exists, NSError *error))completionHandler;

/*!
 * @brief Answers a serialised data representation of the resource according to
 * the configured serialisation format.
 */
- (NSData *)encode;

@end
