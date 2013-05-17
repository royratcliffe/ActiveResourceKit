// ActiveResourceKitTests DynamicTests.m
//
// Copyright © 2013, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import "DynamicTests.h"

#import "Person.h"

@interface ResourceWithADynamicAttribute : ARResource

@property(strong, NS_NONATOMIC_IOSONLY) id attributeWithALongName;

@end

@implementation ResourceWithADynamicAttribute

@dynamic attributeWithALongName;

@end

@implementation DynamicTests

- (void)testDynamicWithSchema
{
	Person *person = [Person new];
	[[person serviceLazily] setSchema:@{@"name": @(@encode(NSString *))}];

	// setter
	person.name = @"Roy";

	// getter
	STAssertEqualObjects(person.name, @"Roy", nil);
}

- (void)testDynamicWithoutSchema
{
	NSString *name;
	Person *person = [Person new];

	// setter throws
	STAssertThrows(person.name = @"Roy", nil);

	// getter throws
	STAssertThrows(name = person.name, nil);
}

- (void)testUnderscoredSchema
{
	ResourceWithADynamicAttribute *resource = [ResourceWithADynamicAttribute new];
	[[resource serviceLazily] setSchema:@{@"attribute_with_a_long_name": @(@encode(id))}];
	STAssertNoThrow([resource attributeWithALongName], nil);
}

- (void)testLowercaseCamelizedSchema
{
	ResourceWithADynamicAttribute *resource = [ResourceWithADynamicAttribute new];
	[[resource serviceLazily] setSchema:@{@"attributeWithALongName": @(@encode(id))}];
	STAssertThrows([resource attributeWithALongName], nil);
}

@end
