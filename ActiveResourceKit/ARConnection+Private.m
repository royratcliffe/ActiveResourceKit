// ActiveResourceKit ARConnection+Private.m
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "ARConnection+Private.h"

@implementation ARConnection(Private)

- (NSDictionary *)defaultHeaders
{
	return [NSDictionary dictionary];
}

- (NSDictionary *)buildRequestHeaderFieldsUsingHeaders:(NSDictionary *)headers forHTTPMethod:(NSString *)HTTPMethod
{
	NSMutableDictionary *headerFields = [NSMutableDictionary dictionaryWithDictionary:[self defaultHeaders]];
	[headerFields addEntriesFromDictionary:[self HTTPFormatHeaderForHTTPMethod:HTTPMethod]];
	if (headers)
	{
		[headerFields addEntriesFromDictionary:headers];
	}
	return [headerFields copy];
}

//------------------------------------------------------------------------------
#pragma mark                                            Format Header for Method
//------------------------------------------------------------------------------

/*!
 * @param array A standard C array of fixed-sized elements.
 * @brief Answers the number of elements in the given array, the array's dimension.
 * @details Assumes that the array argument is a standard C-style array where
 * the compiler can assess the number of elements by dividing the size of the
 * entire array by the size of its elements; the answer always equals an integer
 * since array size is a multiple of element size. Both measurements must be
 * static, otherwise the compiler cannot supply a fixed integer dimension.  The
 * implementation wraps the argument in parenthesis in order to enforce the
 * necessary operator precedence.
 * @note Beware of side effects if you pass operators in the @a array
 * expression. The macro argument evaluates twice.
 */
#define DIMOF(array) (sizeof(array)/sizeof((array)[0]))

- (NSDictionary *)HTTPFormatHeaderForHTTPMethod:(NSString *)HTTPMethod
{
	// Use CFStringRefs rather than NSString pointers when using Automatic
	// Reference Counting. ARC does not allow references within C
	// structures. Toll-free bridging exists between Core Foundation and Next
	// Step strings.
	static struct
	{
		CFStringRef const HTTPMethod;
		CFStringRef const headerName;
	}
	const HTTPFormatHeaderNames[] =
	{
		{ CFSTR("GET"),    CFSTR("Accept") },
		{ CFSTR("PUT"),    CFSTR("Content-Type") },
		{ CFSTR("POST"),   CFSTR("Content-Type") },
		{ CFSTR("DELETE"), CFSTR("Accept") },
		{ CFSTR("HEAD"),   CFSTR("Accept") },
	};
	// Is this too ugly? A dictionary could implement the look-up. But that
	// requires building a static dictionary initially and does not allow
	// optimisation of searching. Using a simple linear look-up speeds up the
	// more common request types, i.e. GET requests. There is a cost, that of
	// slower look-up for less common types, e.g. HEAD. Is this a reasonable
	// trade-off?
	NSUInteger index;
	for (index = 0; index < DIMOF(HTTPFormatHeaderNames); index++)
	{
		if ([HTTPMethod isEqualToString:(__bridge NSString *)HTTPFormatHeaderNames[index].HTTPMethod])
		{
			break;
		}
	}
	NSDictionary *formatHeader;
	if (index < DIMOF(HTTPFormatHeaderNames))
	{
		formatHeader = [NSDictionary dictionaryWithObject:[[self format] MIMEType] forKey:(__bridge NSString *)HTTPFormatHeaderNames[index].headerName];
	}
	else
	{
		formatHeader = [NSDictionary dictionary];
	}
	return formatHeader;
}

@end
