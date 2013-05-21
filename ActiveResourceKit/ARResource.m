// ActiveResourceKit ARResource.m
//
// Copyright © 2011–2013, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import "ARResource.h"
#import "ARResource+Private.h"

// for -[ARService splitOptions:prefixOptions:queryOptions:]
// (This makes you wonder. If other classes need to import the private
// interface, should not the so-called private methods really become public, not
// private?)
#import "ARService+Private.h"

// for ARRemoveRoot(object)
#import "ARFormatMethods.h"

// for AMName
#import <ActiveModelKit/ActiveModelKit.h>

// for ASInflectorUnderscore
#import <ActiveSupportKit/ActiveSupportKit.h>

/**
 * Turns the selector string into an undefined key. Remove the set prefix and
 * the trailing colon. The selector determines which attribute to
 * access. Setters begin with "set" plus the name of the property and a final
 * colon. Remove the prefix and suffix; lower case convert the
 * remainder. Answers `nil` if the selector fails to match the set<Property>:
 * pattern.
 */
NSString *ARUndefinedKeyForSetterSelector(SEL selector);
NSString *ARUndefinedKeyForGetterSelector(SEL selector);

// continuation class
@interface ARResource()
{
	NSMutableDictionary *__strong _attributes;
}

@end

@implementation ARResource

// designated initialiser
- (id)init
{
	self = [super init];
	if (self)
	{
		_attributes = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	ARResource *copy = [[[self class] allocWithZone:zone] init];
	[copy clone:self];
	return copy;
}

- (void)clone:(ARResource *)resource
{
	[self setService:[resource service]];
	// Copy attributes using the standard getter and setter. This does not
	// deep-copy the objects and thereby assumes a simple set of primitive
	// attributes.
	[self setAttributes:[resource attributes]];
	[self setPrefixOptions:[resource prefixOptions]];
	[self setPersisted:[resource persisted]];
}

+ (ARService *)service
{
	ARService *service = [[ARService alloc] init];
	if ([self respondsToSelector:@selector(site)])
	{
		[service setSite:[self performSelector:@selector(site)]];
	}
	if ([self respondsToSelector:@selector(elementName)])
	{
		[service setElementName:[self performSelector:@selector(elementName)]];
	}
	else if (self != [ARResource class] && [self isSubclassOfClass:[ARResource class]])
	{
		[service setElementName:[[[AMName alloc] initWithClass:self] element]];
	}
	return service;
}

- (id)initWithService:(ARService *)service
{
	// This is not the designated initialiser. Sends -init to self not super.
	self = [self init];
	if (self)
	{
		[self setService:service];
	}
	return self;
}

- (id)initWithService:(ARService *)service attributes:(NSDictionary *)attributes
{
	self = [self initWithService:service];
	if (self)
	{
		[self loadAttributes:attributes removeRoot:NO];
	}
	return self;
}

- (id)initWithService:(ARService *)service attributes:(NSDictionary *)attributes persisted:(BOOL)persisted
{
	self = [self initWithService:service attributes:attributes];
	if (self)
	{
		[self setPersisted:persisted];
	}
	return self;
}

- (id)initWithResource:(ARResource *)resource
{
	self = [self init];
	if (self)
	{
		[self clone:resource];
	}
	return self;
}

- (NSDictionary *)foreignID
{
	return [NSDictionary dictionaryWithObject:[self ID] forKey:[[self service] foreignKey]];
}

//------------------------------------------------------------------------------
#pragma mark                                                                Base
//------------------------------------------------------------------------------

@synthesize service = _service;

- (ARService *)serviceLazily
{
	ARService *service = [self service];
	if (service == nil)
	{
		[self setService:service = [[self class] service]];
	}
	return service;
}

//------------------------------------------------------------------------------
#pragma mark                                                          Attributes
//------------------------------------------------------------------------------

// Store attributes using a mutable dictionary. Take care, however, not to
// expose the implementation. The interface only exposes an immutable dictionary
// when answering -attributes. The attributes getter makes an immutable copy of
// the mutable dictionary.

- (NSDictionary *)attributes
{
	return [_attributes copy];
}

- (void)setAttributes:(NSDictionary *)attributes
{
	// Remove all objects in order to maintain "setter" semantics. Otherwise,
	// setting really means merging attributes.
	[_attributes removeAllObjects];
	[self mergeAttributes:attributes];
}

- (void)mergeAttributes:(NSDictionary *)attributes
{
	// Take care not to use -[NSObject setValuesForKeysWithDictionary:] because
	// it filters out all those attributes with null values. By design,
	// resources preserve all attributes, even those with no values.
	for (NSString *attributeName in attributes)
	{
		id attributeValue = [attributes objectForKey:attributeName];
		[_attributes setObject:attributeValue forKey:attributeName];
	}
}

- (void)loadAttributes:(NSDictionary *)attributes removeRoot:(BOOL)removeRoot
{
	NSDictionary *prefixOptions = nil;
	ARService *service = [self serviceLazily];
	[service splitOptions:attributes prefixOptions:&prefixOptions queryOptions:&attributes];
	[self setPrefixOptions:prefixOptions];
	if ([attributes count] == 1)
	{
		removeRoot = [[service elementNameLazily] isEqualToString:[[[attributes allKeys] objectAtIndex:0] description]];
	}
	if (removeRoot)
	{
		attributes = ARRemoveRoot(attributes);
	}
	[self setAttributes:attributes];
}

// Supports key-value coding. Returns attribute values for undefined keys. Hence
// you can access resource attributes on the resource itself rather than
// indirectly via the attributes property.
//
// The “key” argument specifies the key using Cocoa conventions of property
// keys, namely camel-cased with an initial lower-case letter. The method
// implementation converts this to Rails conventions for attribute names, namely
// underscored.
- (id)valueForUndefinedKey:(NSString *)key
{
	return [_attributes objectForKey:[[ASInflector defaultInflector] underscore:key]];
}

// Removes a value if you set the value to nil. Complies with key-value
// observing protocols by sending "will- and did-change value for key" messages.
// Only send will-and-did-change messages if and only if the value changes. Use
// -isEqual: to determine change versus no change.
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	if (value)
	{
		NSString *attributeName = [[ASInflector defaultInflector] underscore:key];
		if (![[_attributes objectForKey:attributeName] isEqual:value])
		{
			[self willChangeValueForKey:key];
			[_attributes setObject:value forKey:attributeName];
			[self didChangeValueForKey:key];
		}
	}
	else
	{
		[self setNilValueForKey:key];
	}
}

- (void)setNilValueForKey:(NSString *)key
{
	NSString *attributeName = [[ASInflector defaultInflector] underscore:key];
	if ([_attributes objectForKey:attributeName])
	{
		[self willChangeValueForKey:key];
		[_attributes removeObjectForKey:attributeName];
		[self didChangeValueForKey:key];
	}
}

/**
 * Transfers values from the resource attributes to a dictionary,
 * answering the dictionary.
 *
 * Accesses the values by sending `-valueForKey:aKey` to `self`,
 * where `aKey` conforms to key-value coding requirements, i.e. lower
 * camel-case. This invokes `-valueForUndefinedKey:aKey` on `self` which
 * performs the `aKey` to `a_key` translation to Rails resource attribute
 * name.
 */
- (NSDictionary *)dictionaryWithValuesForKeys:(NSArray *)keys
{
	NSMutableDictionary *keyedValues = [NSMutableDictionary dictionary];
	for (NSString *key in keys)
	{
		[keyedValues setObject:[self valueForKey:key] forKey:key];
	}
	return [keyedValues copy];
}

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues
{
	for (NSString *key in keyedValues)
	{
		[self setValue:[keyedValues objectForKey:key] forKey:key];
	}
}

//------------------------------------------------------------------------------
#pragma mark                                                      Prefix Options
//------------------------------------------------------------------------------

@synthesize prefixOptions = _prefixOptions;

//------------------------------------------------------------------------------
#pragma mark                                         Schema and Known Attributes
//------------------------------------------------------------------------------

- (NSDictionary *)schema
{
	NSDictionary *schema = [[self serviceLazily] schema];
	return schema ? schema : [self attributes];
}

- (NSArray *)knownAttributes
{
	NSMutableSet *set = [NSMutableSet set];
	[set addObjectsFromArray:[[self serviceLazily] knownAttributes]];
	[set addObjectsFromArray:[[self attributes] allKeys]];
	return [set allObjects];
}

//------------------------------------------------------------------------------
#pragma mark                                                           Persisted
//------------------------------------------------------------------------------

@synthesize persisted = _persisted;

- (BOOL)isNew
{
	return ![self persisted];
}

- (BOOL)isNewRecord
{
	return [self isNew];
}

//------------------------------------------------------------------------------
#pragma mark                                                         Primary Key
//------------------------------------------------------------------------------

- (NSNumber *)ID
{
	id ID = [_attributes objectForKey:[[self serviceLazily] primaryKeyLazily]];
	return ID && [ID isKindOfClass:[NSNumber class]] ? ID : nil;
}

- (void)setID:(NSNumber *)ID
{
	[_attributes setObject:ID forKey:[[self serviceLazily] primaryKeyLazily]];
}

//------------------------------------------------------------------------------
#pragma mark                                                    RESTful Services
//------------------------------------------------------------------------------

- (void)saveWithCompletionHandler:(void (^)(ARHTTPResponse *response, NSError *error))completionHandler
{
	if ([self isNew])
	{
		[self createWithCompletionHandler:completionHandler];
	}
	else
	{
		[self updateWithCompletionHandler:completionHandler];
	}
}

- (void)destroyWithCompletionHandler:(void (^)(ARHTTPResponse *response, NSError *error))completionHandler
{
	[[self serviceLazily] delete:[self elementPathWithOptions:nil] completionHandler:^(ARHTTPResponse *response, id object, NSError *error) {
		completionHandler(response, error);
	}];
}

- (void)existsWithCompletionHandler:(void (^)(ARHTTPResponse *response, BOOL exists, NSError *error))completionHandler
{
	[[self serviceLazily] existsWithID:[self ID] options:nil completionHandler:^(ARHTTPResponse *response, BOOL exists, NSError *error) {
		completionHandler(response, exists, error);
	}];
}

- (NSData *)encode
{
	ARService *service = [self service];
	return [[service formatLazily] encode:[NSDictionary dictionaryWithObject:[self attributes] forKey:[service elementNameLazily]] error:NULL];
}

//------------------------------------------------------------------------------
#pragma mark                                                              Object
//------------------------------------------------------------------------------

- (NSString *)description
{
	NSMutableString *string = [NSMutableString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self];
	ARService *service = [self service];
	if (service)
	{
		NSString *elementName = [service elementName];
		if (elementName)
		{
			[string appendFormat:@" element:%@", elementName];
		}
		NSString *collectionName = [service collectionName];
		if (collectionName)
		{
			[string appendFormat:@" collection:%@", collectionName];
		}
		NSDictionary *attributes = [self attributes];
		for (NSString *attributeName in attributes)
		{
			[string appendFormat:@" %@=%@", attributeName, [attributes objectForKey:attributeName]];
		}
	}
	return [string copy];
}

//------------------------------------------------------------------------------
//
// The implementation could resolve dynamic setters and getters using
// +resolveInstanceMethod:sel. See below. However, this approach works by adding
// method implementations to the ARResource class itself, and hence for all
// instances of ARResource. Not desirable.
//
//	#import <objc/runtime.h>
//
//	+ (BOOL)resolveInstanceMethod:(SEL)sel
//	{
//		NSString *selString = NSStringFromSelector(sel);
//		if ([selString hasPrefix:@"set"] && [selString hasSuffix:@":"])
//		{
//			NSString *lowercase = [[selString substringWithRange:NSMakeRange(3, 1)] lowercaseString];
//			NSString *substring = [selString substringWithRange:NSMakeRange(4, [selString length] - 5)];
//			NSString *undefinedKey = [lowercase stringByAppendingString:substring];
//			return class_addMethod(self, sel, imp_implementationWithBlock(^(ARResource *self, id value) {
//				[self setValue:value forUndefinedKey:undefinedKey];
//			}), "v@:@");
//		}
//		if (![selString hasPrefix:@"get"] && ![selString hasSuffix:@":"])
//		{
//			return class_addMethod(self, sel, imp_implementationWithBlock(^id (ARResource *self) {
//				return [self valueForUndefinedKey:selString];
//			}), "@@:");
//		}
//		return [super resolveInstanceMethod:sel];
//	}
//
//------------------------------------------------------------------------------

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	NSString *key;
	if ((key = ARUndefinedKeyForSetterSelector([anInvocation selector])))
	{
		id value;
		[anInvocation getArgument:&value atIndex:2];
		[self setValue:value forUndefinedKey:key];
	}
	else if ((key = ARUndefinedKeyForGetterSelector([anInvocation selector])))
	{
		id value = [self valueForUndefinedKey:key];
		[anInvocation setReturnValue:&value];
	}
	else [super forwardInvocation:anInvocation];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	// Schemas use Rails attribute naming conventions not Objective-C naming
	// conventions. Dynamic method resolution converts from lower-case camel to
	// underscore form.
	NSString *key;
	if ((key = ARUndefinedKeyForSetterSelector(aSelector)) &&
		[[self knownAttributes] containsObject:[[ASInflector defaultInflector] underscore:key]])
	{
		NSString *types = [NSString stringWithFormat:@"%s%s%s%s", @encode(void), @encode(id), @encode(SEL), @encode(id)];
		return [NSMethodSignature signatureWithObjCTypes:[types UTF8String]];
	}
	if ((key = ARUndefinedKeyForGetterSelector(aSelector)) &&
		[[self knownAttributes] containsObject:[[ASInflector defaultInflector] underscore:key]])
	{
		NSString *types = [NSString stringWithFormat:@"%s%s%s", @encode(id), @encode(id), @encode(SEL)];
		return [NSMethodSignature signatureWithObjCTypes:[types UTF8String]];
	}
	return [super methodSignatureForSelector:aSelector];
}

@end

NSString *ARUndefinedKeyForSetterSelector(SEL selector)
{
	NSString *selectorString = NSStringFromSelector(selector);
	if ([selectorString hasPrefix:@"set"] && [selectorString hasSuffix:@":"])
	{
		NSString *first = [[selectorString substringWithRange:NSMakeRange(3, 1)] lowercaseString];
		NSString *other = [selectorString substringWithRange:NSMakeRange(4, [selectorString length] - 5)];
		return [first stringByAppendingString:other];
	}
	return nil;
}

NSString *ARUndefinedKeyForGetterSelector(SEL selector)
{
	NSString *selectorString = NSStringFromSelector(selector);
	if (![selectorString hasPrefix:@"get"] && ![selectorString hasSuffix:@":"])
	{
		return selectorString;
	}
	return nil;
}
