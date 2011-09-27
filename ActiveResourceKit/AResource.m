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

@implementation AResource

//------------------------------------------------------------------------------
#pragma mark                                                                Base
//------------------------------------------------------------------------------

@synthesize base = _base;

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

//------------------------------------------------------------------------------
#pragma mark                                                          Attributes
//------------------------------------------------------------------------------

@synthesize attributes = _attributes;

- (void)loadAttributes:(NSDictionary *)attributes
{
	[self setAttributes:attributes];
}

//------------------------------------------------------------------------------
#pragma mark                                                      Prefix Options
//------------------------------------------------------------------------------

@synthesize prefixOptions = _prefixOptions;

//------------------------------------------------------------------------------
#pragma mark                                                           Persisted
//------------------------------------------------------------------------------

@synthesize persisted = _persisted;

@end
