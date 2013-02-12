// ActiveResourceKitTests FinderTests.m
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

#import "FinderTests.h"

#import "Person.h"

#import "ActiveResourceKitTests.h"

@implementation FinderTests

- (void)testFindByID
{
	[[Person service] findSingleWithID:[NSNumber numberWithInt:1]
							   options:nil
					 completionHandler:^(ARHTTPResponse *response,
										 ARResource *matz,
										 NSError *error) {
		STAssertNotNil(matz, nil);
		STAssertNil(error, nil);
		
		STAssertTrue([matz isKindOfClass:[Person class]], nil);
		STAssertEqualObjects([matz valueForKey:@"name"], @"Matz", nil);
		STAssertNotNil([[matz attributes] objectForKey:@"name"], nil);
		
		[self setStop:YES];
	}];
	[self runUntilStop];
}

- (void)testFindByIDWithOptions
{
	// The following tests sends exactly the same GET request as above, only it
	// also carries a query string as follows.
	//
	//	/people/1.json?auth_token=XYZ
	//
	[[Person service] findSingleWithID:[NSNumber numberWithInt:1]
							   options:[NSDictionary dictionaryWithObject:@"XYZ" forKey:@"auth_token"]
					 completionHandler:^(ARHTTPResponse *response, ARResource *matz, NSError *error) {
		STAssertNotNil(matz, nil);
		STAssertNil(error, nil);
		
		STAssertTrue([matz isKindOfClass:[Person class]], nil);
		STAssertEqualObjects([matz valueForKey:@"name"], @"Matz", nil);
		STAssertNotNil([[matz attributes] objectForKey:@"name"], nil);
		
		[self setStop:YES];
	}];
	[self runUntilStop];
}

- (void)testFindCollectionWithCustomPrefix
{
	NSUInteger __block pending = 0;
	
	ARService *postService = [[ARService alloc] initWithSite:ActiveResourceKitTestsBaseURL() elementName:@"post"];
	ARService *commentService = [postService serviceForSubelementNamed:@"comment"];
	[postService findAllWithOptions:nil completionHandler:^(ARHTTPResponse *response, NSArray *posts, NSError *error) {
		STAssertNotNil(posts, nil);
		for (ARResource *post in posts)
		{
			// Derive a site URL for the nested resource.
			[commentService findAllWithOptions:[post foreignID] completionHandler:^(ARHTTPResponse *response, NSArray *comments, NSError *error) {
				STAssertNotNil(comments, nil);
				NSLog(@"%@", [post valueForKey:@"title"]);
				for (ARResource *comment in comments)
				{
					NSLog(@"%@", [comment valueForKey:@"text"]);
				}
				
				// Stop the run loop when pending equals zero, but not
				// before. Completion handlers execute when the request
				// responds. Finding a post increments pending. Finding all a
				// post's comments decrements pending. Pending therefore finally
				// becomes zero after finding all posts and finding each one's
				// comments.
				if (--pending == 0) [self setStop:YES];
			}];
			++pending;
		}
		if (pending == 0) [self setStop:YES];
	}];
	[self runUntilStop];
}

@end
