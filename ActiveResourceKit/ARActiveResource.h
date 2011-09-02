// ActiveResourceKit ARActiveResource.h
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

@interface ARActiveResource : NSObject

// The following properties use copy rather than retain. Why use copy? You can
// pass a mutable URL or string. The Active Resource retains a non-mutable copy.

/*!
 * Always set up the site first. Other things depend on this essential
 * property. You cannot fully operate the resource without the site URL. The
 * site's path becomes the default prefix.
 */
@property(copy, NS_NONATOMIC_IPHONEONLY) NSURL *site;

// Setters and getters for element and collection name follow Rails
// semantics. You can set them but they also have default values which the class
// computes whenever you get the property without setting it first. The getter
// examines the current value and if not already set, sets up the default which
// typically accesses other values and possibly other defaults. This Rails-like
// ‘lazy getter’ approach means that you can always override defaults using the
// setter, either before accessing the getter or even afterwards.

@property(copy, NS_NONATOMIC_IPHONEONLY) NSString *prefix;
@property(copy, NS_NONATOMIC_IPHONEONLY) NSString *elementName;
@property(copy, NS_NONATOMIC_IPHONEONLY) NSString *collectionName;

/*!
 * Answers a set of prefix parameters based on the current prefix. These
 * constitute the current set of prefix parameters: an array of strings without
 * the leading colon. Colon immediately followed by a word marks each parameter.
 */
- (NSSet *)prefixParameters;

- (NSString *)prefixWithOptions:(NSDictionary *)options;
- (NSString *)elementPathForID:(NSNumber *)ID prefixOptions:(NSDictionary *)prefixOptions;

@end
