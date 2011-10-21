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

// lazy getter
- (id<ARFormat>)formatLazily
{
	id<ARFormat> format = [self format];
	if (format == nil)
	{
		[self setFormat:format = [self defaultFormat]];
	}
	return format;
}

@synthesize timeout = _timeout;

//------------------------------------------------------------------------------
#pragma mark                                                        Element Name
//------------------------------------------------------------------------------

@synthesize elementName = _elementName;

// lazy getter
- (NSString *)elementNameLazily
{
	NSString *elementName = [self elementName];
	if (elementName == nil)
	{
		[self setElementName:elementName = [self defaultElementName]];
	}
	return elementName;
}

//------------------------------------------------------------------------------
#pragma mark                                                     Collection Name
//------------------------------------------------------------------------------

@synthesize collectionName = _collectionName;

// lazy getter
- (NSString *)collectionNameLazily
{
	NSString *collectionName = [self collectionName];
	if (collectionName == nil)
	{
		[self setCollectionName:collectionName = [self defaultCollectionName]];
	}
	return collectionName;
}

//------------------------------------------------------------------------------
#pragma mark                                                         Primary Key
//------------------------------------------------------------------------------

@synthesize primaryKey = _primaryKey;

- (NSString *)primaryKeyLazily
{
	NSString *primaryKey = [self primaryKey];
	if (primaryKey == nil)
	{
		[self setPrimaryKey:primaryKey = [self defaultPrimaryKey]];
	}
	return primaryKey;
}

//------------------------------------------------------------------------------
#pragma mark                                                              Prefix
//------------------------------------------------------------------------------

@synthesize prefixSource = _prefixSource;

// lazy getter
- (NSString *)prefixSourceLazily
{
	NSString *prefixSource = [self prefixSource];
	if (prefixSource == nil)
	{
		prefixSource = [self defaultPrefixSource];
		
		// Automatically append a trailing slash, but if and only if the prefix
		// source does not already terminate with a slash.
		if ([prefixSource length] == 0 || ![[prefixSource substringFromIndex:[prefixSource length] - 1] isEqualToString:@"/"])
		{
			prefixSource = [prefixSource stringByAppendingString:@"/"];
		}
		
		[self setPrefixSource:prefixSource];
	}
	return prefixSource;
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
		return [self prefixSourceLazily];
	}
	return [[NSRegularExpression regularExpressionWithPattern:@":(\\w+)" options:0 error:NULL] replaceMatchesInString:[self prefixSourceLazily] replacementStringForResult:^NSString *(NSTextCheckingResult *result, NSString *inString, NSInteger offset) {
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
	return [NSString stringWithFormat:@"%@%@/%@.%@%@", [self prefixWithOptions:prefixOptions], [self collectionNameLazily], IDString, [[self formatLazily] extension], ARQueryStringForOptions(queryOptions)];
}

// Answers the path for creating a new element. Note, the term “new” appearing
// at the start of the method name does not, in this case, signify a retained
// result.
- (NSString *)newElementPathWithPrefixOptions:(NSDictionary *)prefixOptions
{
	return [NSString stringWithFormat:@"%@%@/new.%@", [self prefixWithOptions:prefixOptions], [self collectionNameLazily], [[self formatLazily] extension]];
}

- (NSString *)collectionPathWithPrefixOptions:(NSDictionary *)prefixOptions queryOptions:(NSDictionary *)queryOptions
{
	if (queryOptions == nil)
	{
		[self splitOptions:prefixOptions prefixOptions:&prefixOptions queryOptions:&queryOptions];
	}
	return [NSString stringWithFormat:@"%@%@.%@%@", [self prefixWithOptions:prefixOptions], [self collectionNameLazily], [[self formatLazily] extension], ARQueryStringForOptions(queryOptions)];
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

- (void)findAllWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSArray *resources, NSError *error))completionHandler
{
	return [self findEveryWithOptions:options completionHandler:completionHandler];
}

- (void)findFirstWithOptions:(NSDictionary *)options completionHandler:(void (^)(AResource *resource, NSError *error))completionHandler
{
	return [self findEveryWithOptions:options completionHandler:^(NSArray *resources, NSError *error) {
		completionHandler(resources && [resources count] ? [resources objectAtIndex:0] : nil, error);
	}];
}

- (void)findLastWithOptions:(NSDictionary *)options completionHandler:(void (^)(AResource *resource, NSError *error))completionHandler
{
	return [self findEveryWithOptions:options completionHandler:^(NSArray *resources, NSError *error) {
		completionHandler(resources && [resources count] ? [resources lastObject] : nil, error);
	}];
}

- (void)findOneWithOptions:(NSDictionary *)options completionHandler:(void (^)(AResource *resource, NSError *error))completionHandler
{
	NSString *from = [options objectForKey:kARFromKey];
	if (from && [from isKindOfClass:[NSString class]])
	{
		NSString *path = [NSString stringWithFormat:@"%@%@", from, ARQueryStringForOptions([options objectForKey:kARParamsKey])];
		[self get:path completionHandler:^(id object, NSError *error) {
			if ([object isKindOfClass:[NSDictionary class]])
			{
				completionHandler([self instantiateRecordWithAttributes:object prefixOptions:nil], nil);
			}
			else
			{
				completionHandler(nil, [NSError errorWithDomain:ARErrorDomain code:ARUnsupportedRootObjectTypeError userInfo:nil]);
			}
		}];
	}
}

- (void)findSingleForID:(NSNumber *)ID options:(NSDictionary *)options completionHandler:(void (^)(AResource *resource, NSError *error))completionHandler
{
	NSDictionary *prefixOptions = nil;
	NSDictionary *queryOptions = nil;
	[self splitOptions:options prefixOptions:&prefixOptions queryOptions:&queryOptions];
	NSString *path = [self elementPathForID:ID prefixOptions:prefixOptions queryOptions:queryOptions];
	[self get:path completionHandler:^(id object, NSError *error) {
		if ([object isKindOfClass:[NSDictionary class]])
		{
			completionHandler([self instantiateRecordWithAttributes:object prefixOptions:prefixOptions], nil);
		}
		else
		{
			completionHandler(nil, [NSError errorWithDomain:ARErrorDomain code:ARUnsupportedRootObjectTypeError userInfo:nil]);
		}
	}];
}

@end
