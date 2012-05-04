/* ActiveResourceKit ActiveResourceKit.h
 *
 * Copyright © 2011, 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the “Software”), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in
 *	all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
 * EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 ******************************************************************************/

#import <ActiveResourceKit/ARIncrementalStore.h>
#import <ActiveResourceKit/ARResource.h>
#import <ActiveResourceKit/ARService.h>
#import <ActiveResourceKit/ARConnection.h>
#import <ActiveResourceKit/ARURLConnection.h>
#import <ActiveResourceKit/ARSynchronousLoadingURLConnection.h>
#import <ActiveResourceKit/ARQueuedLoadingURLConnection.h>
#import <ActiveResourceKit/ARHTTPResponse.h>
#import <ActiveResourceKit/NSPersistentStore+ActiveResource.h>
#import <ActiveResourceKit/NSManagedObject+ActiveResource.h>
#import <ActiveResourceKit/NSEntityDescription+ActiveResource.h>
#import <ActiveResourceKit/NSAttributeDescription+ActiveResource.h>

#import <ActiveResourceKit/ARFormatMethods.h>
#import <ActiveResourceKit/ARJSONFormat.h>

#import <ActiveResourceKit/ARHTTPMethods.h>
#import <ActiveResourceKit/ARErrors.h>
#import <ActiveResourceKit/ARMacros.h>
#import <ActiveResourceKit/Versioning.h>

/*!
 * @mainpage Active Resource Kit
 *
 * What can you do with Active Resource Kit?  Active Resource Kit is yet-another
 * RESTful framework. There are others. But Active Resource Kit has a number of
 * distinct features.
 * 1. It mirrors the Rails Active Resource gem closely. The interface and
 * implementation remain as faithful as an Objective-C implementation can
 * reasonably be to the Ruby-based originals.
 * 2. It offers a very high-level interface to RESTful resources using Core
 * Data. You can access remote resources just as if they were in a local Core
 * Data store. The implementation uses the new Core Data @c NSIncrementalStore
 * API to merge the two dissimilar interfaces.
 * 3. It only has Foundation and Core Data as underlying dependencies. Although
 * it has two immediate dependencies, Active Model Kit and Active Support Kit
 * which fall under the same umbrella framework, Apple's Foundation and Core
 * Data kits form the only @em external dependencies. The implementation employs
 * only the Foundation framework for network access.
 * 4. The framework supports various concurrency models when interacting with
 * remote resources: these are the same models offered by Apple's Foundation @c
 * NSURLConnection class, i.e. delegated URL connections, synchronous loading or
 * queued loading. You can configure according to your requirements on a
 * resource-by-resource basis.
 * 5. There are no swizzles or other non-standard Objective-C tricks. The
 * framework makes extensive use of C blocks for handling completions for both
 * asynchronous and synchronous interfaces; this simply follows the pattern set
 * by Apple in their URL connection API.
 *
 * @section setting_up Setting Up an Active Resource-Based Core Data Stack
 *
 * This is easy to do. Just follow the usual Core Data-prescribed procedure:
 * load the model, load the coordinator with the model, add the store to the
 * coordinator, and finally attach the coordinator to the context. See example
 * below.
 *
 * @code
 *	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
 *	NSURL *modelURL = [bundle URLForResource:@"MyCoreDataModel" withExtension:@"momd"];
 *	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
 *	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
 *
 *	NSError *__autoreleasing error = nil;
 *	NSPersistentStore *store = [coordinator addPersistentStoreWithType:[ARIncrementalStore storeType]
 *	                                                     configuration:nil
 *	                                                               URL:[NSURL URLWithString:@"http://localhost:3000"]
 *	                                                           options:nil
 *	                                                             error:&error];
 *	// <-- error handling goes here
 *
 *	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
 *	[context setPersistentStoreCoordinator:coordinator];
 *	[self setContext:context];
 * @endcode
 *
 * Note that this excerpt uses Automatic Reference Counting, hence the @c
 * __autoreleasing specifier for the error pointer. Notice the blatant lack of
 * manual auto-releasing.
 *
 * @section accessing_resources Accessing Resources
 *
 * You can then access resources using @em only Core Data.
 *
 * @code
 *	NSError *__autoreleasing error = nil;
 *	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
 *	NSArray *people = [[self context] executeFetchRequest:request error:&error];
 *	for (NSManagedObject *person in people)
 *	{
 *	    NSString *name = [person valueForKey:@"name"];
 *	    NSLog(@"person named %@", name);
 *	}
 * @endcode
 *
 * You ask Core Data for the Person entities. The answer is a collection of
 * managed object representing each Person. You access attributes on the objects
 * using standard Cocoa key-value coding. However, underneath the hood, the
 * Active Resource incremental store has enacted a RESTful GET request at
 * http://localhost:3000/people.json, decoding and caching the active resources
 * at the client side.
 */
