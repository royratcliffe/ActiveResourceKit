// ActiveResourceKit ARBase.m
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

#import "ARBase.h"
#import "ARBase+Private.h"

#import "AResource.h"
#import "ARErrors.h"

#import <ActiveSupportKit/ActiveSupportKit.h>

@implementation ARBase

// designated initialiser
- (id)init
{
	self = [super init];
	if (self)
	{
		[self setTimeout:60.0];
	}
	return self;
}

//------------------------------------------------------------------------------
#pragma mark                                                              Schema
//------------------------------------------------------------------------------

@synthesize schema = _schema;

- (NSArray *)knownAttributes
{
	return [[self schema] allKeys];
}

//------------------------------------------------------------------------------
#pragma mark                                                                Site
//------------------------------------------------------------------------------

@synthesize site = _site;

// The following initialisers are not designated initialisers. Note the messages
// to -[self init] rather than -[super init], a small but important
// difference. These are just convenience initialisers: a way to initialise and
// assign the site URL at one and the same time, or site plus element name.

- (id)initWithSite:(NSURL *)site
{
	self = [self init];
	if (self)
	{
		[self setSite:site];
	}
	return self;
}

- (id)initWithSite:(NSURL *)site elementName:(NSString *)elementName
{
	self = [self initWithSite:site];
	if (self)
	{
		[self setElementName:elementName];
	}
	return self;
}

//------------------------------------------------------------------------------
#pragma mark                                                              Format
//------------------------------------------------------------------------------

@synthesize format = _format;

// getter
- (id<ARFormat>)format
{
	if (_format == nil)
	{
		[self setFormat:[self defaultFormat]];
	}
	return _format;
}

// setter
- (void)setFormat:(id<ARFormat>)newFormat
{
	if (_format != newFormat)
	{
		[_format autorelease];
		_format = [newFormat retain];
	}
}

@synthesize timeout = _timeout;

//------------------------------------------------------------------------------
#pragma mark                                                        Element Name
//------------------------------------------------------------------------------

@synthesize elementName = _elementName;

- (NSString *)elementName
{
	if (_elementName == nil)
	{
		[self setElementName:[self defaultElementName]];
	}
	return _elementName;
}

- (void)setElementName:(NSString *)newElementName
{
	if (_elementName != newElementName)
	{
		[_elementName autorelease];
		_elementName = [newElementName copy];
	}
}

//------------------------------------------------------------------------------
#pragma mark                                                     Collection Name
//------------------------------------------------------------------------------

@synthesize collectionName = _collectionName;

- (NSString *)collectionName
{
	if (_collectionName == nil)
	{
		[self setCollectionName:[self defaultCollectionName]];
	}
	return _collectionName;
}

- (void)setCollectionName:(NSString *)newCollectionName
{
	if (_collectionName != newCollectionName)
	{
		[_collectionName autorelease];
		_collectionName = [newCollectionName copy];
	}
}

//------------------------------------------------------------------------------
#pragma mark                                                              Prefix
//------------------------------------------------------------------------------

@synthesize prefixSource = _prefixSource;

// getter
- (NSString *)prefixSource
{
	if (_prefixSource == nil)
	{
		NSString *prefixSource = [self defaultPrefixSource];
		if ([prefixSource length] == 0 || ![[prefixSource substringFromIndex:[prefixSource length] - 1] isEqualToString:@"/"])
		{
			prefixSource = [prefixSource stringByAppendingString:@"/"];
		}
		[self setPrefixSource:prefixSource];
	}
	return _prefixSource;
}

// It would be nice for the compiler to provide the setter. If you make the
// property non-atomic, the compiler will let you define just the custom
// getter. But not so if you make the property atomic. Is this a compiler
// feature or bug? It outputs a warning message, “writable atomic property
// cannot pair a synthesised setter/getter with a user defined setter/getter.”

// setter
- (void)setPrefixSource:(NSString *)newPrefixSource
{
	if (_prefixSource != newPrefixSource)
	{
		[_prefixSource autorelease];
		// Auto-release the previous prefix source, assuming there is one. This
		// allows the caller to access the previous prefix source first, then
		// alter the prefix source and retain access to the original copy. The
		// original will disappear from memory at the next pool-drain event
		// having received the auto-release message.
		_prefixSource = [newPrefixSource copy];
	}
}

- (NSString *)prefixWithOptions:(NSDictionary *)options
{
	// The following implementation duplicates some of the functionality
	// concerning extraction of prefix parameters from the prefix. See the
	// -prefixParameters method. Nevertheless, the replace-in-place approach
	// makes the string operations more convenient. The implementation does not
	// need to cut apart the colon from its parameter word. The regular
	// expression identifies the substitution on our behalf, making it easier to
	// remove the colon, access the prefix parameter minus its colon and replace
	// both; and all at the same time.
	if (options == nil)
	{
		return [self prefixSource];
	}
	return [[NSRegularExpression regularExpressionWithPattern:@":(\\w+)" options:0 error:NULL] replaceMatchesInString:[self prefixSource] replacementStringForResult:^NSString *(NSTextCheckingResult *result, NSString *inString, NSInteger offset) {
		return [[[options objectForKey:[[result regularExpression] replacementStringForResult:result inString:inString offset:offset template:@"$1"]] description] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}];
}

//------------------------------------------------------------------------------
#pragma mark                                                               Paths
//------------------------------------------------------------------------------

- (NSString *)elementPathForID:(NSNumber *)ID prefixOptions:(NSDictionary *)prefixOptions queryOptions:(NSDictionary *)queryOptions
{
	if (queryOptions == nil)
	{
		[self splitOptions:prefixOptions prefixOptions:&prefixOptions queryOptions:&queryOptions];
	}
	NSString *IDString = [[ID stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return [NSString stringWithFormat:@"%@%@/%@.%@%@", [self prefixWithOptions:prefixOptions], [self collectionName], IDString, [[self format] extension], ARQueryStringForOptions(queryOptions)];
}

// Answers the path for creating a new element.
- (NSString *)newElementPathWithPrefixOptions:(NSDictionary *)prefixOptions
{
	return [NSString stringWithFormat:@"%@%@/new.%@", [self prefixWithOptions:prefixOptions], [self collectionName], [[self format] extension]];
}

- (NSString *)collectionPathWithPrefixOptions:(NSDictionary *)prefixOptions
{
	return [NSString stringWithFormat:@"%@%@.%@", [self prefixWithOptions:prefixOptions], [self collectionName], [[self format] extension]];
}

// Building with attributes. Should this be a class or instance method? Rails
// implements this as a class method, or to be more specific, a singleton
// method. Objective-C does not provide the singleton class
// paradigm. ActiveResourceKit folds the Rails singleton methods to instance
// methods.
- (void)buildWithAttributes:(NSDictionary *)attributes completionHandler:(void (^)(AResource *resource, NSError *error))completionHandler
{
	// Use the new element path. Construct the request URL using this path but
	// make it relative to the site URL. The NSURL class combines the new
	// element path with the site, using the site's scheme, host and port.
	NSString *path = [self newElementPathWithPrefixOptions:nil];
	[self get:path completionHandler:^(id object, NSError *error) {
		if ([object isKindOfClass:[NSDictionary class]])
		{
			NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:object];
			[attrs addEntriesFromDictionary:attributes];
			completionHandler([[[AResource alloc] initWithBase:self attributes:attrs] autorelease], nil);
		}
		else
		{
			// The response body decodes successfully but it does not
			// decode to a dictionary. It must be something else, either
			// an array, a string or some other primitive type. In which
			// case, building with attributes must fail even though
			// ostensibly the operation has succeeded. Set up an error.
			completionHandler(nil, [NSError errorWithDomain:ARErrorDomain code:ARUnsupportedRootObjectTypeError userInfo:nil]);
		}
	}];
}

- (void)findAllWithPrefixOptions:(NSDictionary *)prefixOptions completionHandler:(void (^)(NSArray *resources, NSError *error))completionHandler
{
	NSString *path = [self collectionPathWithPrefixOptions:nil];
	[self get:path completionHandler:^(id object, NSError *error) {
		if ([object isKindOfClass:[NSArray class]])
		{
			completionHandler([self instantiateCollection:object prefixOptions:prefixOptions], nil);
		}
		else
		{
			completionHandler(nil, [NSError errorWithDomain:ARErrorDomain code:ARUnsupportedRootObjectTypeError userInfo:nil]);
		}
	}];
}

@end
