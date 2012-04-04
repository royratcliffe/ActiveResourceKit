// ActiveResourceKitTests KeyValueCodingTests.m
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import "KeyValueCodingTests.h"

#import <ActiveResourceKit/ActiveResourceKit.h>

@implementation KeyValueCodingTests

@synthesize resource;

- (void)setUp
{
	ARService *service = [[ARService alloc] initWithSite:[NSURL URLWithString:@"http://localhost"] elementName:@"resource"];
	[self setResource:[[ARResource alloc] initWithService:service]];
	[[self resource] setValue:[NSNumber numberWithInt:0] forKey:@"zero"];
}

- (void)tearDown
{
	[self setResource:nil];
}

- (void)testValueForUndefinedKey
{
	STAssertEqualObjects([NSNumber numberWithInt:0], [[self resource] valueForKey:@"zero"], nil);
}

- (void)testSetNilValue
{
	[[self resource] setValue:@"" forKey:@"key"];
	STAssertEqualObjects(@"", [[self resource] valueForKey:@"key"], nil);
	
	[[self resource] setNilValueForKey:@"key"];
	STAssertEqualObjects([NSNull null], [[self resource] valueForKey:@"key"], nil);
}

- (void)testAttributeKeyVersusKVCKey
{
	[[self resource] setValue:@"123" forKey:@"TheKey"];
	STAssertEqualObjects(@"123", [[[self resource] attributes] objectForKey:@"the_key"], nil);
}

- (void)testValuesForKeys
{
	[[self resource] setValue:@"abc" forKey:@"KeyA"];
	[[self resource] setValue:@"def" forKey:@"KeyB"];
	NSDictionary *valuesForKeys = [[self resource] dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"KeyA", @"KeyB", nil]];
	NSDictionary *shouldBeValuesForKeys = [NSDictionary dictionaryWithObjectsAndKeys:@"abc", @"KeyA", @"def", @"KeyB", nil];
	STAssertEqualObjects(shouldBeValuesForKeys, valuesForKeys, nil);
}

- (void)testSetValuesForKeys
{
	NSDictionary *valuesForKeys = [NSDictionary dictionaryWithObjectsAndKeys:@"abc", @"KeyABC", @"xyz", @"KeyXYZ", [NSNull null], @"Null", nil];
	[[self resource] setValuesForKeysWithDictionary:valuesForKeys];
	NSDictionary *attributes = [[self resource] attributes];
	STAssertEqualObjects([attributes objectForKey:@"key_abc"], @"abc", nil);
	STAssertEqualObjects([attributes objectForKey:@"key_xyz"], @"xyz", nil);
	STAssertEqualObjects([attributes objectForKey:@"null"], [NSNull null], nil);
}

@end
