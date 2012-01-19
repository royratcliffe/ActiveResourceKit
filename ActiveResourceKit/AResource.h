// ActiveResourceKit AResource.h
//
// Copyright © 2011, Roy Ratcliffe, Pioneering Software, United Kingdom
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

@class ARBase;

/*!
 * @brief Provides the core class mirroring Rails' @c ActiveResource::Base class.
 * @details An active resource mimics an active record. Resources behave as
 * records. Only their connection fundamentally differs. Active Records connect
 * to a database whereas Active Resources connect to a RESTful API accessed via
 * HTTP transport.
 *
 * @image html Class_Diagram__Base_and_Resource.png
 *
 * @par AResource or ARResource?
 * This class uses AResource as the class name rather than ARResource. A is for
 * Active, R for Resource. But the namespace convention for Objective-C lends
 * itself to AResource if you eliminate the repeated term. Hence, ARResource
 * becomes AResource!
 */
@interface AResource : NSObject<AMAttributeMethods>

/*!
 * @brief Constructs an active resource base using class methods to establish
 * the site and element name.
 * @details If the AResource sub-class has a class method called +site, use its
 * answer to set up the Active Resource site. This assumes that +site answers an
 * NSURL object. Similarly, sets up the base element name by sending
 * +elementName to the sub-class, answering a string. However, if the sub-class
 * does not implement the +elementName class method, the element name derives
 * from the AResource sub-class name.
 */
+ (ARBase *)base;

- (id)initWithBase:(ARBase *)base;

- (id)initWithBase:(ARBase *)base attributes:(NSDictionary *)attributes;

- (id)initWithBase:(ARBase *)base attributes:(NSDictionary *)attributes persisted:(BOOL)persisted;

//------------------------------------------------------------------------- Base

/*!
 * Retains the active-resource base. Does not copy the base. This has important
 * implications. If you alter base properties, the changes affect all the
 * resources which depend upon it.
 */
@property(strong, NS_NONATOMIC_IOSONLY) ARBase *base;

/*!
 * @brief Asks for the resource base, lazily constructing a base instance if the
 * resource does not currently retain a base.
 * @details Asks the class for a site URL and an element name. Optionally
 * implement @c +site and @c +elementName to supply the URL and element name. If
 * your class does not supply an implementation for @c +elementName, the element
 * name derives from the sub-class name. This assumes that you do not directly
 * instantiate the AResource class. If you do, the element name remains @c nil.
 */
- (ARBase *)baseLazily;

//------------------------------------------------------------------- Attributes

@property(copy, NS_NONATOMIC_IOSONLY) NSDictionary *attributes;

/*!
 * Argument @a removeRoot becomes a do-not-care if @a attributes contains just a
 * single key-object pair. In such a case, removing the root depends on whether
 * or not the single key matches the base element name.
 */
- (void)loadAttributes:(NSDictionary *)attributes removeRoot:(BOOL)removeRoot;

//--------------------------------------------------------------- Prefix Options

@property(copy, NS_NONATOMIC_IOSONLY) NSDictionary *prefixOptions;

//-------------------------------------------------- Schema and Known Attributes

- (NSDictionary *)schema;

/*!
 * @brief Answers all the known attributes belonging to this active resource, a
 * unique array of attribute key strings.
 * @details The resulting array includes all the base's known attributes plus
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

- (void)saveWithCompletionHandler:(void (^)(id object, NSError *error))completionHandler;

@end
