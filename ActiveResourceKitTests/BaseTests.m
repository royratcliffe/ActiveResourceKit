// ActiveResourceKitTests BaseTests.m
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

#import "BaseTests.h"
#import "Person.h"

#import <ActiveResourceKit/ActiveResourceKit.h>

@implementation BaseTests

- (void)testCreate
{
	[[Person service] createWithAttributes:[NSDictionary dictionaryWithObject:@"Rick" forKey:@"name"] completionHandler:^(ARHTTPResponse *response, ARResource *resource, NSError *error) {
		STAssertNotNil(resource, nil);
		[self setStop:YES];
	}];
	[self runUntilStop];
}

- (void)testDestroy
{
	ARService *peopleService = [Person service];
	[peopleService createWithAttributes:[NSDictionary dictionaryWithObject:@"Roy" forKey:@"name"] completionHandler:^(ARHTTPResponse *response, ARResource *resource, NSError *error) {
		STAssertNotNil(resource, nil);
		[resource destroyWithCompletionHandler:^(ARHTTPResponse *response, NSError *error) {
			STAssertEquals([response code], (NSInteger)200, nil);
			[self setStop:YES];
		}];
	}];
	[self runUntilStop];
}

- (void)testExists
{
	ARService *peopleService = [Person service];
	
	// Do not execute a run loop with nil IDs. The answer (exists equal to NO)
	// comes back immediately. The completion block runs before the
	// exists-with-ID method returns.
	[peopleService existsWithID:nil options:nil completionHandler:^(ARHTTPResponse *response, BOOL exists, NSError *error) {
		STAssertFalse(exists, nil);
	}];
	
	[peopleService existsWithID:[NSNumber numberWithInt:1] options:nil completionHandler:^(ARHTTPResponse *response, BOOL exists, NSError *error) {
		STAssertTrue(exists, nil);
		[self setStop:YES];
	}];
	[self runUntilStop];
	
	[peopleService existsWithID:[NSNumber numberWithInt:99] options:nil completionHandler:^(ARHTTPResponse *response, BOOL exists, NSError *error) {
		STAssertFalse(exists, nil);
		STAssertEquals([response code], (NSInteger)404, nil);
		STAssertEquals([error code], (NSInteger)ARResourceNotFoundErrorCode, nil);
		[self setStop:YES];
	}];
	[self runUntilStop];
	
	Person *person = [[Person alloc] init];
	[person existsWithCompletionHandler:^(ARHTTPResponse *response, BOOL exists, NSError *error) {
		STAssertFalse(exists, nil);
	}];
}

- (void)testToJSON
{
	[[Person service] findSingleWithID:[NSNumber numberWithInt:6] options:nil completionHandler:^(ARHTTPResponse *response, ARResource *joe, NSError *error) {
		NSString *string = [[NSString alloc] initWithData:[response body] encoding:NSUTF8StringEncoding];
		for (NSString *re in [NSArray arrayWithObjects:@"\"id\":6", @"\"name\":\"Joe\"", nil])
		{
			STAssertNotNil([[NSRegularExpression regularExpressionWithPattern:re options:0 error:NULL] firstMatchInString:string options:0 range:NSMakeRange(0, [string length])], @"%@ should find match in %@", re, string);
		}
		[self setStop:YES];
	}];
	[self runUntilStop];
}

@end
