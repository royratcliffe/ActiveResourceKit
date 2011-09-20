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
#import "ARJSONFormat.h"
#import "Errors.h"

#import <ActiveModelKit/ActiveModelKit.h>
#import <ActiveSupportKit/ActiveSupportKit.h>

@interface ARBase()

@end

@interface ARBase(Private)

- (NSString *)defaultPrefix;
- (NSString *)defaultElementName;
- (NSString *)defaultCollectionName;

/*!
 * Sends an asynchronous GET request. When the response successfully arrives,
 * the format decodes the data. If the response body decodes successfully,
 * finally sends the decoded object (or objects) to your given completion
 * handler. Objects may be hashes (dictionaries) or arrays, or even primitives.
 */
- (void)get:(NSString *)path completionHandler:(void (^)(id object, NSError *error))completionHandler;

@end

@implementation ARBase

@synthesize timeout = _timeout;

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

@synthesize attributes = _attributes;

- (void)loadAttributes:(NSDictionary *)attributes
{
	[self setAttributes:attributes];
}

@synthesize site = _site;

// This is not the designated initialiser. Note the message to -[self init]
// rather than -[super init], a small but important difference. This is just a
// convenience initialiser: a way to initialise and assign the site URL at one
// and the same time. The default initialiser is the standard initialiser
// inherited from NSObject.
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

- (id<ARFormat>)format
{
	if (_format == nil)
	{
		[self setFormat:[ARJSONFormat JSONFormat]];
	}
	return _format;
}

- (void)setFormat:(id<ARFormat>)newFormat
{
	if (_format != newFormat)
	{
		[_format autorelease];
		_format = [newFormat retain];
	}
}

//------------------------------------------------------------------------------
#pragma mark                                                              Prefix
//------------------------------------------------------------------------------

@synthesize prefix = _prefix;

- (NSString *)prefix
{
	if (_prefix == nil)
	{
		NSString *prefix = [self defaultPrefix];
		if ([prefix length] == 0 || ![[prefix substringFromIndex:[prefix length] - 1] isEqualToString:@"/"])
		{
			prefix = [prefix stringByAppendingString:@"/"];
		}
		[self setPrefix:prefix];
	}
	return _prefix;
}

// It would be nice for the compiler to provide the setter. If you make the
// property non-atomic, the compiler will let you define just the custom
// getter. But not so if you make the property atomic. Is this a compiler
// feature or bug? It outputs a warning message, “writable atomic property
// cannot pair a synthesised setter/getter with a user defined setter/getter.”

- (void)setPrefix:(NSString *)newPrefix
{
	if (_prefix != newPrefix)
	{
		[_prefix autorelease];
		// Auto-release the previous prefix, assuming there is one. This allows
		// the caller to access the previous prefix first, alter the prefix and
		// retain access to the original copy. The original will disappear from
		// memory at the next pool-drain event having received the auto-release
		// message.
		_prefix = [newPrefix copy];
	}
}

- (NSSet *)prefixParameters
{
	NSMutableSet *parameters = [NSMutableSet set];
	NSString *prefix = [self prefix];
	for (NSString *match in [[NSRegularExpression regularExpressionWithPattern:@":\\w+" options:0 error:NULL] matchesInString:[self prefix] options:0 range:NSMakeRange(0, [prefix length])])
	{
		[parameters addObject:[match substringFromIndex:1]];
	}
	return [[parameters copy] autorelease];
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
		return [self prefix];
	}
	return [[NSRegularExpression regularExpressionWithPattern:@":(\\w+)" options:0 error:NULL] replaceMatchesInString:[self prefix] replacementStringForResult:^NSString *(NSTextCheckingResult *result, NSString *inString, NSInteger offset) {
		return [[[options objectForKey:[[result regularExpression] replacementStringForResult:result inString:inString offset:offset template:@"$1"]] description] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}];
}

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
#pragma mark                                                               Paths
//------------------------------------------------------------------------------

- (NSString *)elementPathForID:(NSNumber *)ID prefixOptions:(NSDictionary *)prefixOptions
{
	NSString *IDString = [[ID stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return [NSString stringWithFormat:@"%@%@/%@.%@", [self prefixWithOptions:prefixOptions], [self collectionName], IDString, [[self format] extension]];
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
- (void)buildWithAttributes:(NSDictionary *)attributes completionHandler:(void (^)(NSDictionary *attrs, NSError *error))completionHandler
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
			[self loadAttributes:attrs];
			completionHandler(attrs, nil);
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

- (ARBase *)instantiateRecord:(NSDictionary *)record prefix:(NSString *)prefix
{
	ARBase *resource = [[[ARBase alloc] initWithSite:[self site]] autorelease];
	[resource loadAttributes:record];
	[resource setPrefix:prefix];
	return resource;
}

- (NSArray *)instantiateCollection:(NSArray *)collection prefix:(NSString *)prefix
{
	NSMutableArray *resources = [NSMutableArray array];
	for (NSDictionary *record in collection)
	{
		[resources addObject:[self instantiateRecord:record prefix:prefix]];
	}
	return [[resources copy] autorelease];
}

- (void)findAllWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSArray *resources, NSError *error))completionHandler
{
	NSString *path = [self collectionPathWithPrefixOptions:nil];
	[self get:path completionHandler:^(id object, NSError *error) {
		if ([object isKindOfClass:[NSArray class]])
		{
			completionHandler([self instantiateCollection:object prefix:[self prefix]], nil);
		}
		else
		{
			completionHandler(nil, [NSError errorWithDomain:ARErrorDomain code:ARUnsupportedRootObjectTypeError userInfo:nil]);
		}
	}];
}

@end

@implementation ARBase(Private)

- (NSString *)defaultPrefix
{
	return [[self site] path];
}

- (NSString *)defaultElementName
{
	return [[[[AMName alloc] initWithClass:[self class]] autorelease] element];
}

- (NSString *)defaultCollectionName
{
	return [[ASInflector defaultInflector] pluralize:[self elementName]];
}

- (void)get:(NSString *)path completionHandler:(void (^)(id object, NSError *error))completionHandler
{
	NSURL *URL = [NSURL URLWithString:path relativeToURL:[self site]];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:[self timeout]];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		if (data)
		{
			id object = [[self format] decode:data error:&error];
			if (object)
			{
				completionHandler(object, nil);
			}
			else
			{
				completionHandler(nil, error);
			}
		}
		else
		{
			completionHandler(nil, error);
		}
	}];
}

@end
