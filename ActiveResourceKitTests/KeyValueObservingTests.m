// ActiveResourceKitTests KeyValueObservingTests.m
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

#import "KeyValueObservingTests.h"
#import "Person.h"

@interface KeyValueObservingTests()

@property(strong, nonatomic) Person *person;
@property(assign, nonatomic) NSUInteger changeSetting;

@end

@implementation KeyValueObservingTests

- (void)setUp
{
	// Construct a person. Observe its name. When the name changes, assert the
	// change from nil to something and back.
	self.person = [Person new];
	[[self.person serviceLazily] setSchema:@{@"name": @(@encode(id))}];
	[self.person addObserver:self forKeyPath:@"name" options:0 context:NULL];
}

- (void)tearDown
{
	[self.person removeObserver:self forKeyPath:@"name"];
	self.person = nil;
}

- (void)testPersonChangesNameFromNilToXYZ
{
	self.changeSetting = 0;
	self.person.name = nil;
	STAssertNil(self.person.name, nil);
	self.person.name = @"XYZ";
	STAssertEqualObjects(self.person.name, @"XYZ", nil);
	STAssertEquals(self.changeSetting, (NSUInteger)2, nil);
}

- (void)testPersonChangesNameFromXYZToNil
{
	self.changeSetting = 0;
	self.person.name = @"XYZ";
	STAssertEqualObjects(self.person.name, @"XYZ", nil);
	self.person.name = nil;
	STAssertNil(self.person.name, nil);
	STAssertEquals(self.changeSetting, (NSUInteger)2, nil);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	STAssertEquals(object, self.person, nil);
	STAssertNotNil([change objectForKey:NSKeyValueChangeKindKey], nil);
	STAssertTrue([[change objectForKey:NSKeyValueChangeKindKey] isKindOfClass:[NSNumber class]], nil);
	STAssertEquals([[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue], NSKeyValueChangeSetting, nil);
	self.changeSetting++;
}

@end
