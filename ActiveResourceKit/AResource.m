// ActiveResourceKit AResource.m
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

#import "AResource.h"
#import "AResource+Private.h"

// for -[ARBase splitOptions:prefixOptions:queryOptions:]
// (This makes you wonder. If other classes need to import the private
// interface, should not the so-called private methods really become public, not
// private?)
#import "ARBase+Private.h"

// for ARRemoveRoot(object)
#import "ARFormatMethods.h"

// for AMName
#import <ActiveModelKit/ActiveModelKit.h>

@implementation AResource

- (id)initWithBase:(ARBase *)base
{
	// This is not the designated initialiser. Sends -init to self not super.
	self = [self init];
	if (self)
	{
		[self setBase:base];
	}
	return self;
}

- (id)initWithBase:(ARBase *)base attributes:(NSDictionary *)attributes
{
	self = [self init];
	if (self)
	{
		[self loadAttributes:attributes removeRoot:NO];
	}
	return self;
}

- (id)initWithBase:(ARBase *)base attributes:(NSDictionary *)attributes persisted:(BOOL)persisted
{
	self = [self initWithBase:base attributes:attributes];
	if (self)
	{
		[self setPersisted:persisted];
	}
	return self;
}

//------------------------------------------------------------------------------
#pragma mark                                                                Base
//------------------------------------------------------------------------------

@synthesize base = _base;

- (ARBase *)baseLazily
{
	ARBase *base = [self base];
	if (base == nil)
	{
		[self setBase:base = [[[ARBase alloc] init] autorelease]];
		if ([[self class] respondsToSelector:@selector(site)])
		{
			[base setSite:[[self class] performSelector:@selector(site)]];
		}
		if ([[self class] respondsToSelector:@selector(elementName)])
		{
			[base setElementName:[[self class] performSelector:@selector(elementName)]];
		}
		else if ([self class] != [AResource class])
		{
			[base setElementName:[[[[AMName alloc] initWithClass:[self class]] autorelease] element]];
		}
	}
	return base;
}

//------------------------------------------------------------------------------
#pragma mark                                                          Attributes
//------------------------------------------------------------------------------

@synthesize attributes = _attributes;

- (void)loadAttributes:(NSDictionary *)attributes removeRoot:(BOOL)removeRoot
{
	NSDictionary *prefixOptions = nil;
	[[self baseLazily] splitOptions:attributes prefixOptions:&prefixOptions queryOptions:&attributes];
	if ([attributes count] == 1)
	{
		removeRoot = [[[self baseLazily] elementName] isEqualToString:[[[attributes allKeys] objectAtIndex:0] description]];
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
- (id)valueForUndefinedKey:(NSString *)key
{
	return [[self attributes] objectForKey:key];
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
	NSDictionary *schema = [[self baseLazily] schema];
	return schema ? schema : [self attributes];
}

- (NSArray *)knownAttributes
{
	NSMutableSet *set = [NSMutableSet set];
	[set addObjectsFromArray:[[self baseLazily] knownAttributes]];
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
	id ID = [[self attributes] objectForKey:[[self baseLazily] primaryKey]];
	return ID && [ID isKindOfClass:[NSNumber class]] ? ID : nil;
}

- (void)setID:(NSNumber *)ID
{
	// The (current) implementation does not retain a mutable dictionary
	// suitable for modification. Consequently, setting the ID requires a
	// mutable duplicate temporarily. Resetting the attributes with an updated
	// primary key snapshots an immutable copy of the mutable dictionary. The
	// attributes thereby return to their immutable state.
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributes]];
	[attributes setObject:ID forKey:[[self baseLazily] primaryKey]];
	[self setAttributes:attributes];
}

@end
