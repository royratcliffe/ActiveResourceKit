# Active Resource Kit

What can you do with Active Resource Kit?  Active Resource Kit is yet-another
RESTful framework. There are others. But Active Resource Kit has a number of
distinct features.

1. It mirrors the Rails Active Resource gem closely. The interface and
implementation remain as faithful as an Objective-C implementation can
reasonably be to the Ruby-based originals.
2. It offers a very high-level interface to RESTful resources using Core
Data. You can access remote resources just as if they were in a local Core
Data store. The implementation uses the new Core Data `NSIncrementalStore`
API to merge the two dissimilar interfaces.
3. It only has Foundation and Core Data as underlying dependencies. Although
it has two immediate dependencies, Active Model Kit and Active Support Kit
which fall under the same umbrella framework, Apple's Foundation and Core
Data kits form the only _external_ dependencies. The implementation employs
only the Foundation framework for network access.
4. The framework supports various concurrency models when interacting with
remote resources: these are the same models offered by Apple's Foundation
`NSURLConnection` class, i.e. delegated URL connections, synchronous loading or
queued loading. You can configure according to your requirements on a
resource-by-resource basis.
5. There are no swizzles or other non-standard Objective-C tricks. The
framework makes extensive use of C blocks for handling completions for both
asynchronous and synchronous interfaces; this simply follows the pattern set
by Apple in their URL connection API.

## Setting Up an Active Resource-Based Core Data Stack

This is easy to do. Just follow the usual Core Data-prescribed procedure:
load the model, load the coordinator with the model, add the store to the
coordinator, and finally attach the coordinator to the context. See example
below.

	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *modelURL = [bundle URLForResource:@"MyCoreDataModel" withExtension:@"momd"];
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	NSError *__autoreleasing error = nil;
	NSPersistentStore *store = [coordinator addPersistentStoreWithType:[ARIncrementalStore storeType]
	                                                     configuration:nil
	                                                               URL:[NSURL URLWithString:@"http://localhost:3000"]
	                                                           options:nil
	                                                             error:&error];
	// <-- error handling goes here

	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	[context setPersistentStoreCoordinator:coordinator];
	[self setContext:context];

Note that this excerpt uses Automatic Reference Counting, hence the
`__autoreleasing` specifier for the error pointer. Notice the blatant lack of
manual auto-releasing.

## Accessing Resources

You can then access resources using _only_ Core Data.

	NSError *__autoreleasing error = nil;
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
	NSArray *people = [[self context] executeFetchRequest:request error:&error];
	for (NSManagedObject *person in people)
	{
	    NSString *name = [person valueForKey:@"name"];
	    NSLog(@"person named %@", name);
	}

You ask Core Data for the Person entities. The answer is a collection of
managed object representing each Person. You access attributes on the objects
using standard Cocoa key-value coding. However, underneath the hood, the
Active Resource incremental store has enacted a RESTful GET request at
http://localhost:3000/people.json, decoding and caching the active resources
at the client side.

At the other side of the connection (assuming your server runs on Rails; it
does not need to be Rails but can be any conforming RESTful interface) you
will see a GET request in the server log, as follows. Some details elided.

	Started GET "/people.json" for 127.0.0.1 at …
	Processing by PeopleController#index as JSON
	  Person Load (0.2ms)  SELECT "people".* FROM "people"
	Completed 200 OK in 5ms (Views: 3.8ms | ActiveRecord: 0.2ms)

### Inserting Resources

This just becomes fuss-free:

	NSError *__autoreleasing error = nil;
	NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:[self context]];
	[person setValue:@"Roy Ratcliffe" forKey:@"name"];
	BOOL yes = [[self context] save:&error];

And on the server side becomes a familiar POST request:

	Started POST "/people.json" for 127.0.0.1 at …
	Processing by PeopleController#create as JSON
	  Parameters: {"person"=>{"name"=>"Roy Ratcliffe"}}
	   (0.1ms)  begin transaction
	  SQL (0.4ms)  INSERT INTO "people" ("created_at", "name", "updated_at") VALUES (?, ?, ?)  [["created_at", …], ["name", "Roy Ratcliffe"], ["updated_at", …]]
	   (2.3ms)  commit transaction
	Completed 201 Created in 5ms (Views: 0.8ms | ActiveRecord: 2.8ms)

### Deleting Resources

Again, just very simply:

	NSError *__autoreleasing error = nil;
	[[self context] deleteObject:person];
	BOOL yes = [[self context] save:&error];

And the server responds:

	Started DELETE "/people/16.json" for 127.0.0.1 at …
	Processing by PeopleController#destroy as JSON
	  Parameters: {"id"=>"16"}
	  Person Load (0.1ms)  SELECT "people".* FROM "people" WHERE "people"."id" = ? LIMIT 1  [["id", "16"]]
	   …
	  SQL (0.3ms)  DELETE FROM "people" WHERE "people"."id" = ?  [["id", 16]]
	   …
	Completed 200 OK in 15ms (ActiveRecord: 12.7ms)

### Forming Associations

You can conveniently form associations between objects and their remote
resources using only the Core Data interface.

The following demonstrates what happens when you instantiate two entities and
wire them up entirely at the client side first. Lets say you have a post and
comment model; posts have many comments, a one post to many comments
association. The following initially creates a post with one comment.

	NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:[self context]];
	NSManagedObject *comment = [NSEntityDescription insertNewObjectForEntityForName:@"Comment" inManagedObjectContext:[self context]];
	
	// Set up attributes for the post and the comment.
	[post setValue:@"De finibus bonorum et malorum" forKey:@"title"];
	[post setValue:@"Non eram nescius…" forKey:@"body"];
	[comment setValue:@"Quae cum dixisset…" forKey:@"text"];
	
	// Form the one-post-to-many-comments association.
	[comment setValue:post forKey:@"post"];
	
	// Send it all to the server.
	NSError *__autoreleasing error = nil;
	[[self context] save:&error];

It constructs a new post, a new comment and their relationship within the
client at first. Then it saves the context in order to transfer the objects and
their relationship to the remote server.

Thereafter, you can throw away the comment and refetch it by dereferencing the
post's "comments" relationship. The following extract pulls out each text field
from the comments based on a given post.

	NSMutableArray *comments = [NSMutableArray array];
	for (NSManagedObject *comment in [post valueForKey:@"comments"])
	{
		[comments addObject:[comment valueForKey:@"text"]];
	}
	[[comments objectAtIndex:0] rangeOfString:@"Quae cum dixisset"].location != NSNotFound;

# Design Notes

## Goals

Memory is a major issue on devices running iOS. Such phones and tablets only
have either 128, 256 or 512MB of RAM.

## Connections

Cocoa's Foundation framework supports three distinct URL connections. Active
Resource Kit models them using four object classes: one abstract with three
corresponding concrete implementation classes.

![Class Diagram: Connections](https://github.com/royratcliffe/ActiveResourceKit/raw/master/Documents/Class_Diagram__Connections.png)

## Lazy Getting

Rails makes extensive use of the lazy getter paradigm: attributes remain
undefined until you access them for the first time. This is a useful model. It
postpones instantiation of dependencies, such as format and connection, until
actually needed. Hence clients can easily override before use to customise
behaviour.

The cross-platform requirement clashes with lazily-getting for this project
however.

## Testing

Run tests by selecting either the ActiveResourceKitFramework or
ActiveResourceKitLibrary targets. Selecting Run » Tests (Cmd+U shortcut)
launches the tests.

In the background, the schemes run a Thin server. This assumes that you do not
already have a Thin server up and running for the Rails test application. If you
do have a server already running in the background, the tests terminate the
current background instance in order to set up and prime the fixtures, before
launching a new server instance. This happens quite quickly; Thin is a
fast-loading web server.

The test launcher script assumes that you have RVM installed as well as the
expected version of Ruby; see `active-resource-kit-tests/.rvmrc`. After
installing RVM, install the required Ruby and the required Gems, as follows.

	cd active-resource-kit-tests
	rvm install ruby-1.9.2-p320
	bundle install

### Viewing the Test Server Log

You can view the test servers log using the command:

	➜  active-resource-kit-tests git:(master) tail -f log/thin.log

### Rails Base URL

The kit's test target launches a Rails application in the background. The Xcode
schemes run a Thin server using the URL scheme, address and port passed by the
`RAILS_BASE_URL` environment variable. You can find this variable, along with
the default `RAILS_ENV` setting, in the project build settings under
User-Defined as follows.

	RAILS_BASE_URL = https://localhost:3000
	RAILS_ENV = development

Since the default URL scheme specifies `https`, the test launches Thin with the
`--ssl` option. This enables SSL over HTTP encrypted communication. Changing
the build setting to use `http` rather than `https` disables the `--ssl`
option. This proves useful when debugging the server-side in tandom, e.g. when
you cannot conveniently debug with SSL enabled. Just switch the build setting
to `RAILS_BASE_URL = http://localhost:3000` (insecure) and launch the Rails app
as normal.

## Resource Associations

When resources load at the client side, what binds their associations? How can
the client resolve foreign keys? To do so, the client needs to identify the
active resources.

Using the principle of convention over configuration, `ARBase` registers its
instances by default, and each `ARBase` retains its `AResource`s. Hence it can
resolve the association whenever a new resource appears with an ID matching some
existing foreign key. Similarly when a new record comprising an unresolved
foreign key loads, `ARBase` can resolve it against an existing resource.

## Incremental Stores

Apple provide a useful Core Data component called `NSIncrementalStore`, designed
for interacting with external stores which do not bring all data into memory the
way atomic stores do. Data loads and stores incrementally. Incremental stores
let you plug RESTful resources into a standard Core Data stack.

One important drawback exists however. Incremental stores, at the current
version, do not accommodate _asynchronous_ network communication. Core Data
sends execute-request messages to the store, expecting the store to respond with
results immediately on return. You can respond with faults but doing so requires
you to know object identities for faulting. Problem is, you cannot execute a
fetch request with faulting object identities without some server interaction.
Unless the code blocks for synchronous communication, you cannot return with
anything else except an error.

## Rails Kit Sub-Framework

Active Resource Kit is designed as a sub-framework on Mac OS X, though not so in
iOS. Framework requirements mandate the following build setting within the Rails
Kit sub-frameworks.

	DYLIB_INSTALL_NAME_BASE = "@executable_path/../Frameworks/RailsKit.framework/Versions/Current/Frameworks"

It tells an application to look for the sub-framework at the given location
relative to the application binary within the application bundle. This makes an
assumption: that you locate the RailsKit.framework within the bundle. The
sub-frameworks exist as sub-sub-frameworks within the application bundle. Hence
the install-name base path specifies the `RailsKit.framework`'s `Frameworks`
sub-folder.

