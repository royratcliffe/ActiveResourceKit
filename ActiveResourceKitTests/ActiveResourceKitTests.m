// ActiveResourceKitTests ActiveResourceKitTests.m
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

#import "ActiveResourceKitTests.h"
#import <ActiveResourceKit/ActiveResourceKit.h>

@interface MyObject : ARBase
@end
@implementation MyObject
@end

@interface Post : ARBase
@end
@implementation Post
@end

@implementation ActiveResourceKitTests

- (void)setUp
{
	post = [[Post alloc] init];
	[post setSite:[NSURL URLWithString:@"http://localhost:3000"]];
}

- (void)tearDown
{
	[post release];
}

- (void)testSetUpSite
{
	// Start off with a very simple test. Just set up a resource. Load it with
	// its site URL. Then ensure that the site property responds as it should,
	// i.e. as an URL. This test exercises NSURL more than
	// ARActiveResource. Never mind.
	//
	// Make sure that the site URL can accept “prefix parameters,” as Rails dubs
	// them. This term refers to path elements beginning with a colon and
	// followed by a regular-expression word. ActiveResourceKit substitutes
	// these for actual parameters.
	ARBase *resource = [[[ARBase alloc] init] autorelease];
	[resource setSite:[NSURL URLWithString:@"http://user:password@localhost:3000/resources/:resource_id?x=y;a=b"]];
	STAssertEqualObjects([[resource site] scheme], @"http", nil);
	STAssertEqualObjects([[resource site] user], @"user", nil);
	STAssertEqualObjects([[resource site] password], @"password", nil);
	STAssertEqualObjects([[resource site] host], @"localhost", nil);
	STAssertEqualObjects([[resource site] port], [NSNumber numberWithInt:3000], nil);
	STAssertEqualObjects([[resource site] path], @"/resources/:resource_id", nil);
	STAssertEqualObjects([[resource site] query], @"x=y;a=b", nil);
}

- (void)testEmptyPath
{
	// Empty URL paths should become empty strings after parsing. This tests the
	// Foundation frameworks implementation of an URL.
	ARBase *resource = [[[ARBase alloc] init] autorelease];
	[resource setSite:[NSURL URLWithString:@"http://user:password@localhost:3000"]];
	STAssertEqualObjects([[resource site] path], @"", nil);
}

- (void)testPrefixSource
{
	// Running the following piece of Ruby:
	//
	//	require 'active_resource'
	//	
	//	class Resource < ActiveResource::Base
	//	  self.prefix = '/resources/:resource_id'
	//	end
	//	
	//	p Resource.prefix(:resource_id => 1)
	//
	// gives you the following output:
	//
	//	"/resources/1"
	//
	// The following test performs the same thing but using Objective-C.
	//
	// Note that the options can contain numbers and other objects. Method
	// -[ARActiveResource prefixWithOptions:] places the “description” of the
	// object answering to the prefix-parameter key (resource_id in this test
	// case). Hence the options dictionary can contain various types answering
	// to -[NSObject description], not just strings.
	ARBase *resource = [[[ARBase alloc] init] autorelease];
	[resource setPrefix:@"/resources/:resource_id"];
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"resource_id"];
	NSString *prefix = [resource prefixWithOptions:options];
	STAssertEqualObjects(prefix, @"/resources/1", nil);
}

- (void)testPrefixParameterWithPercentEscapes
{
	ARBase *resource = [[[ARBase alloc] init] autorelease];
	[resource setPrefix:@"/resources/:resource_id"];
	NSString *prefix = [resource prefixWithOptions:[NSDictionary dictionaryWithObject:@"some text" forKey:@"resource_id"]];
	STAssertEqualObjects(prefix, @"/resources/some%20text", nil);
}

- (void)testElementName
{
	STAssertEqualObjects([[[[MyObject alloc] init] autorelease] elementName], @"my_object", nil);
}

- (void)testCollectionName
{
	STAssertEqualObjects([[[[MyObject alloc] init] autorelease] collectionName], @"my_objects", nil);
}

- (void)testElementPath
{
	NSString *elementPath = [post elementPathForID:[NSNumber numberWithInt:1] prefixOptions:nil];
	STAssertEqualObjects(elementPath, @"/posts/1.json", nil);
}

- (void)testNewElementPath
{
	NSString *newElementPath = [post newElementPathWithPrefixOptions:nil];
	STAssertEqualObjects(newElementPath, @"/posts/new.json", nil);
}

- (void)testCollectionPath
{
	NSString *collectionPath = [post collectionPathWithPrefixOptions:nil];
	STAssertEqualObjects(collectionPath, @"/posts.json", nil);
}

- (void)testJSONFormat
{
	ARJSONFormat *format = [ARJSONFormat JSONFormat];
	STAssertEqualObjects([format extension], @"json", nil);
	STAssertEqualObjects([format MIMEType], @"application/json", nil);
}

@end
