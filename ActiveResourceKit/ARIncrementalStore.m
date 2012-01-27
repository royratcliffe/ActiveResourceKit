// ActiveResourceKit ARIncrementalStore.m
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

#import "ARIncrementalStore.h"

@implementation ARIncrementalStore

+ (NSString *)storeTypeForClass:(Class)klass
{
	return NSStringFromClass(klass);
}

+ (void)registerStoreTypeForClass:(Class)klass
{
	[NSPersistentStoreCoordinator registerStoreClass:klass forStoreType:[self storeTypeForClass:klass]];
}

//------------------------------------------------------------------------------
#pragma mark                                  Incremental Store Method Overrides
//------------------------------------------------------------------------------

// The following methods appear in Core Data's public interface for
// NSIncrementalStore. Implementations below override the abstract interface
// laid out by Core Data.

- (BOOL)loadMetadata:(NSError *__autoreleasing *)outError
{
	NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
	[metadata setObject:[ARIncrementalStore storeTypeForClass:[self class]] forKey:NSStoreTypeKey];
	
	// Assigning a Universally-Unique ID is essential. Without this the next
	// invocation of -setMetadata: will recurse infinitely.
	CFUUIDRef uuid = CFUUIDCreate(NULL);
	[metadata setObject:(__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid) forKey:NSStoreUUIDKey];
	CFRelease(uuid);
	
	[self setMetadata:[metadata copy]];
	return YES;
}

- (id)executeRequest:(NSPersistentStoreRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)outError
{
	switch ([request requestType])
	{
		case NSFetchRequestType:
			return [self executeFetchRequest:(NSFetchRequest *)request withContext:context error:outError];
		case NSSaveRequestType:
			return [self executeSaveRequest:(NSSaveChangesRequest *)request withContext:context error:outError];
	}
	return nil;
}

/*!
 * @result If the request is a fetch request whose result type is set to one of
 * @c NSManagedObjectResultType, @c NSManagedObjectIDResultType, @c
 * NSDictionaryResultType, returns an array containing all objects in the store
 * matching the request. If the request is a fetch request whose result type is
 * set to @c NSCountResultType, returns an array containing an @c NSNumber of
 * all objects in the store matching the request.
 */
- (id)executeFetchRequest:(NSFetchRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)outError
{
	id result;
	switch ([request resultType])
	{
		case NSCountResultType:
			result = [NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:0]];
			break;
		default:
			result = [NSArray array];
	}
	return result;
}

- (id)executeSaveRequest:(NSSaveChangesRequest *)request withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)outError
{
	return [NSArray array];
}

@end
