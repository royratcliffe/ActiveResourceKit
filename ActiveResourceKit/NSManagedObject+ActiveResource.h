// ActiveResourceKit NSManagedObject+ActiveResource.h
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

@interface NSManagedObject(ActiveResource)

/*!
 * @brief Loads attributes from a given resource.
 * @details Performs date conversions, using the managed object's entity
 * description to discover attributes. This approach makes an important
 * assumption: that your managed-object model represents the resource schema, or
 * at least part of the schema. There is only one difference: the naming
 * convention. The Core Data schema uses camel-case; the resource schema uses
 * underscored names. This method does not validate the schema however. It
 * silently ignores resource attributes that do not appear in the managed-object
 * model.
 */
- (void)loadAttributesFromResource:(ARResource *)resource;

@end
