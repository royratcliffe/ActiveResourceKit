// ActiveResourceKit ARURLConnectionDelegate.m
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

#import "ARURLConnectionDelegate.h"

@implementation ARURLConnectionDelegate

@synthesize completionHandler = _completionHandler;
@synthesize response          = _response;
@synthesize data              = _data;

//------------------------------------------------------------------------------
#pragma mark                                                 Connection Delegate
//------------------------------------------------------------------------------

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self completionHandler]([self response], nil, error);
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return YES;
}

/*!
 * @brief Responds to authentication challenges.
 * @details The connection @em cannot continue without credentials in order to
 * access HTTPS resources. Creates a credential, passing it to the
 * authentication challenge's sender. Sends “server trust” provided by the
 * protection space of the authentication challenge.
 */
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
	NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
	[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}

//------------------------------------------------------------------------------
#pragma mark                                            Connection Data Delegate
//------------------------------------------------------------------------------

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[self setResponse:response];
	[self setData:[NSMutableData data]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[[self data] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self completionHandler]([self response], [[self data] copy], nil);
}

@end
