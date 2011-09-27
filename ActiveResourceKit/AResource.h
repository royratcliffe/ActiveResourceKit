// ActiveResourceKit AResource.h
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

#import <Foundation/Foundation.h>

@class ARBase;

/*!
 * AResource is the core class mirroring Rails' ActiveResource::Base class. An
 * active resource mimics an active record. Resources behave as records. Only
 * their connection fundamentally differs. Active Records connect to a database
 * whereas Active Resources connect to a RESTful API accessed via HTTP
 * transport.
 *
 * This class uses AResource as the class name rather than ARResource. A is for
 * Active, R for Resource. But the namespace convention for Objective-C lends
 * itself to AResource if you eliminate the repeated term. Hence, ARResource
 * becomes AResource!
 */
@interface AResource : NSObject
{
@private
	
}

//------------------------------------------------------------------------- Base

@property(retain, NS_NONATOMIC_IOSONLY) ARBase *base;

- (id)initWithBase:(ARBase *)base;

//------------------------------------------------------------------- Attributes

@property(copy, NS_NONATOMIC_IOSONLY) NSDictionary *attributes;

- (void)loadAttributes:(NSDictionary *)attributes;

//--------------------------------------------------------------- Prefix Options

@property(copy, NS_NONATOMIC_IOSONLY) NSDictionary *prefixOptions;

//-------------------------------------------------------------------- Persisted

@property(assign, NS_NONATOMIC_IOSONLY) BOOL persisted;

@end
