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
 * coordinator, and finally attach the coordinator to the context.
 *
 * See example below. There are some things to especially notice. First, the
 * persistent store type specifies the @c ARIncrementalStore type. The URL
 * specifies the remote resource, its protocol, host and path. Protocol can be
 * @c http, or @c https if you want secure transport. The path can specify the
 * site root, i.e. an empty or single-slash path, or can also include a sub-path
 * nested within the remote site. The client-side data model must correspond to
 * the remote's RESTful interface. The Active Resource incremental store
 * utilises the client-side data model in order to deduce the entities, their
 * properties and relationships. Core Data itself requires a valid data model.
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
 *
 * At the other side of the connection (assuming your server runs on Rails; it
 * does not need to be Rails but can be any conforming RESTful interface) you
 * will see a GET request in the server log, as follows. Some details elided.
 * @code
 *	Started GET "/people.json" for 127.0.0.1 at …
 *	Processing by PeopleController#index as JSON
 *	  Person Load (0.2ms)  SELECT "people".* FROM "people"
 *	Completed 200 OK in 5ms (Views: 3.8ms | ActiveRecord: 0.2ms)
 * @endcode
 *
 * @subsection inserting_resources Inserting Resources
 *
 * This just becomes fuss-free:
 * @code
 *	NSError *__autoreleasing error = nil;
 *	NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:[self context]];
 *	[person setValue:@"Roy Ratcliffe" forKey:@"name"];
 *	BOOL yes = [[self context] save:&error];
 * @endcode
 * And on the server side becomes a familiar POST request:
 * @code
 *	Started POST "/people.json" for 127.0.0.1 at …
 *	Processing by PeopleController#create as JSON
 *	  Parameters: {"person"=>{"name"=>"Roy Ratcliffe"}}
 *	   (0.1ms)  begin transaction
 *	  SQL (0.4ms)  INSERT INTO "people" ("created_at", "name", "updated_at") VALUES (?, ?, ?)  [["created_at", …], ["name", "Roy Ratcliffe"], ["updated_at", …]]
 *	   (2.3ms)  commit transaction
 *	Completed 201 Created in 5ms (Views: 0.8ms | ActiveRecord: 2.8ms)
 * @endcode
 *
 * @subsection deleting_resources Deleting Resources
 *
 * Again, just very simply:
 * @code
 *	NSError *__autoreleasing error = nil;
 *	[[self context] deleteObject:person];
 *	BOOL yes = [[self context] save:&error];
 * @endcode
 * And the server responds:
 * @code
 *	Started DELETE "/people/16.json" for 127.0.0.1 at …
 *	Processing by PeopleController#destroy as JSON
 *	  Parameters: {"id"=>"16"}
 *	  Person Load (0.1ms)  SELECT "people".* FROM "people" WHERE "people"."id" = ? LIMIT 1  [["id", "16"]]
 *	   …
 *	  SQL (0.3ms)  DELETE FROM "people" WHERE "people"."id" = ?  [["id", 16]]
 *	   …
 *	Completed 200 OK in 15ms (ActiveRecord: 12.7ms)
 * @endcode
 *
 * @subsection forming_associations Forming Associations
 *
 * You can conveniently form associations between objects and their remote
 * resources using only the Core Data interface.
 *
 * The following demonstrates what happens when you instantiate two entities and
 * wire them up entirely at the client side first. Lets say you have a post and
 * comment model; posts have many comments, a one post to many comments
 * association. The following initially creates a post with one comment.
 *
 * @code
 *	NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:[self context]];
 *	NSManagedObject *comment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:[self context]];
 *	
 *	// Set up attributes for the post and the comment.
 *	[post setValue:@"De finibus bonorum et malorum" forKey:@"title"];
 *	[post setValue:@"Non eram nescius…" forKey:@"body"];
 *	[comment setValue:@"Quae cum dixisset…" forKey:@"text"];
 *	
 *	// Form the one-post-to-many-comments association.
 *	[comment setValue:post forKey:@"post"];
 *	
 *	// Send it all to the server.
 *	NSError *__autoreleasing error = nil;
 *	[[self context] save:&error];
 * @endcode
 *
 * It constructs a new post, a new comment and their relationship within the
 * client at first. Then it saves the context in order to transfer the objects and
 * their relationship to the remote server.
 *
 * Thereafter, you can throw away the comment and refetch it by dereferencing the
 * post's "comments" relationship. The following extract pulls out each text field
 * from the comments based on a given post.
 *
 * @code
 *	NSMutableArray *comments = [NSMutableArray array];
 *	for (NSManagedObject *comment in [post valueForKey:@"comments"])
 *	{
 *		[comments addObject:[comment valueForKey:@"text"]];
 *	}
 *	[[comments objectAtIndex:0] rangeOfString:@"Quae cum dixisset"].location != NSNotFound;
 * @endcode
 */
