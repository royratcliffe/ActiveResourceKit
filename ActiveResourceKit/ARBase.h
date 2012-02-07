// ActiveResourceKit ARBase.h
//
// Copyright © 2011, 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
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
#import <ActiveResourceKit/ARFormat.h>

extern NSString *const ARFromKey;
extern NSString *const ARParamsKey;

@class ARResource;

/*!
 * @brief Defines a completion handler block type where the results of
 * completion yield a single resource.
 * @details Successful completion gives a single instance.
 */
typedef void (^ARResourceCompletionHandler)(ARResource *resource, NSError *error);

/*!
 * @brief Defines a type of completion handler block where successful completion
 * yields an array of resources.
 * @details The completion handler's @a resources argument equals @c nil when
 * completion ends unsuccessfully. In this case, the second argument @a error
 * supplies the reason.
 */
typedef void (^ARResourcesCompletionHandler)(NSArray *resources, NSError *error);

/*!
 * @brief An active resource's base configuration.
 * @details Defines an active resource's site, schema and known attributes,
 * etc. Does not however define an active resource @e instance. Active resources
 * binding to the same remote element at the same remote site associate with a
 * common base.
 *
 * ARBase corresponds to the singleton class aspects of @c
 * ActiveResource::Base. Under Rails ActiveResource, the @c ActiveResource::Base
 * singleton class carries the following state. See list below.
 *
 *	- auth_type
 *	- collection_name
 *	- connection
 *	- element_name
 *	- headers
 *	- known_attributes
 *	- nospam
 *	- password
 *	- prefix_parameters
 *	- primary_key
 *	- proxy
 *	- schema
 *	- site
 *	- ssl_options
 *	- test
 *	- timeout
 *	- user
 *
 * This might help to define what ARBase actually does, its purpose. ARBase
 * implements the anonymous singleton class behaviours belonging to
 * @c ActiveResource::Base. ARResource defines the class for Active Resource
 * instances, but ARBase defines the class for Active Resource @e classes,
 * singleton classes that is. Objective-C 2.0 does not provide anything
 * comparable singleton classes. The Rails singleton class becomes the
 * Objective-C “base” class.
 *
 * Singleton methods for @c ActiveResource::Base include the following.
 *
 *	- all
 *	- auth_type
 *	- build
 *	- check_prefix_options
 *	- collection_name
 *	- collection_path
 *	- connection
 *	- create
 *	- create_proxy_uri_from
 *	- create_site_uri_from
 *	- delete
 *	- element_name
 *	- element_path
 *	- exists
 *	- find
 *	- find_every
 *	- find_one
 *	- find_single
 *	- first
 *	- format
 *	- headers
 *	- instantiate_collection
 *	- instantiate_record
 *	- known_attributes
 *	- last
 *	- new_element_path
 *	- password
 *	- prefix
 *	- prefix_parameters
 *	- prefix_source
 *	- primary_key
 *	- proxy
 *	- query_string
 *	- schema
 *	- site
 *	- split_options
 *	- ssl_options
 *	- timeout
 *	- user
 *
 * @par Lazy Getters
 * Use a getter-lazily paradigm in place of actual lazy getting. This has
 * advantages. First, it obviates the need for defining custom getters and
 * setters. This is a useful thing, since the exact setter and getter
 * implementations depend on the memory model being deployed. Automatic
 * Reference Counting (ARC) has one requirement, garbage-collection another, and
 * manual retain-release (MRR) another. Strategy employed here: Let the compiler
 * synthesise the correct setters and getters accordingly. If you want to access
 * the getter but with lazy initialisation, ask for propertyLazily.
 */
@interface ARBase : NSObject

/*!
 * @brief Initialises a new Active Resource Base instance using a given @a site.
 * @param site An URL specifying the remote HTTP or HTTPS resource.
 * @details This is @em not the designated initialiser but rather a shorthand
 * for sending @c -init followed by @c -setSite:. The element name, if you do
 * not subsequently assign one, derives from the @ref ARBase sub-class
 * name. This assumes that you derive ARBase.
 */
- (id)initWithSite:(NSURL *)site;
- (id)initWithSite:(NSURL *)site elementName:(NSString *)elementName;

// The following properties use copy, in general, rather than retain. Why use
// copy? You can pass a mutable URL or string. The Active Resource retains a
// non-mutable copy.
//
// Note also that Rails implements some of the behaviours at class scope. For
// example, format is a class-scoped attribute in Rails. The Objective-C
// implementation here maps such behaviour to instances rather than classes.

//-------------------------------------------------- Schema and Known Attributes

@property(copy, NS_NONATOMIC_IOSONLY) NSDictionary *schema;

/*!
 * @brief Answers the known attributes, known because the resource server
 * publishes them; although the server does not necessarily publish everything.
 * @details Known attributes depend on schema. The result amounts to the
 * schema's keys. The schema is a dictionary of attribute name-type pairs.
 */
- (NSArray *)knownAttributes;

//------------------------------------------------------------------------- Site

/*!
 * Always set up the site first. Other things depend on this essential
 * property. You cannot fully operate the resource without the site URL. The
 * site's path becomes the default prefix.
 */
@property(copy, NS_NONATOMIC_IOSONLY) NSURL *site;

//----------------------------------------------------------------------- Format

@property(strong, NS_NONATOMIC_IOSONLY) id<ARFormat> format;

// lazy getter
- (id<ARFormat>)formatLazily;

//---------------------------------------------------------------------- Timeout

@property(assign, NS_NONATOMIC_IOSONLY) NSTimeInterval timeout;

//------------------------------------------------- Element and Collection Names

// Setters and getters for element and collection name follow Rails
// semantics. You can set them but they also have default values which the class
// computes whenever you get the property without setting it first. The getter
// examines the current value and if not already set, sets up the default which
// typically accesses other values and possibly other defaults. This Rails-like
// ‘lazy getter’ approach means that you can always override defaults using the
// setter, either before accessing the getter or even afterwards, only provided
// that the property has remained unrequired.

@property(copy, NS_NONATOMIC_IOSONLY) NSString *elementName;
@property(copy, NS_NONATOMIC_IOSONLY) NSString *collectionName;

// lazy getters
- (NSString *)elementNameLazily;
- (NSString *)collectionNameLazily;

//------------------------------------------------------------------ Primary Key

@property(copy, NS_NONATOMIC_IOSONLY) NSString *primaryKey;

- (NSString *)primaryKeyLazily;

//----------------------------------------------------------------------- Prefix

@property(copy, NS_NONATOMIC_IOSONLY) NSString *prefixSource;

// lazy getter
- (NSString *)prefixSourceLazily;

/*!
 * Answers the prefix after translating the prefix parameters according to the
 * given prefix-options dictionary. The options dictionary may be nil. In that
 * case -prefixWithOptions: answers the prefix unmodified. This assumes that the
 * prefix contains no untranslated prefix parameters. The method quietly fails
 * if you do not provide mappings for all parameters. The prefix result will
 * contain parameter placeholders.
 */
- (NSString *)prefixWithOptions:(NSDictionary *)options;

//------------------------------------------------------------------------ Paths

- (NSString *)elementPathForID:(NSNumber *)ID prefixOptions:(NSDictionary *)prefixOptions queryOptions:(NSDictionary *)queryOptions;
- (NSString *)newElementPathWithPrefixOptions:(NSDictionary *)prefixOptions;
- (NSString *)collectionPathWithPrefixOptions:(NSDictionary *)prefixOptions queryOptions:(NSDictionary *)queryOptions;

//------------------------------------------------------------- RESTful Services

// The remote RESTful services offer the following basic actions.
//
//	- build
//	- create
//	- find
//		* every
//		* single
//		* one
//	- delete
//	- exists?

/*!
 * Asynchronously builds an Active Resource.
 *
 * Executes the completion handler on success or upon error. Completion handler
 * arguments signal the outcome: non-nil attributes indicate successful
 * completion. In such case, error always equals nil. There is no error.
 */
- (void)buildWithAttributes:(NSDictionary *)attributes completionHandler:(ARResourceCompletionHandler)completionHandler;

- (void)findAllWithOptions:(NSDictionary *)options completionHandler:(ARResourcesCompletionHandler)completionHandler;

/*!
 * Answers just the first resource in a collection of resources. Finds all the
 * resources first, then extracts the first element. Acts as a convenience
 * wrapper.
 */
- (void)findFirstWithOptions:(NSDictionary *)options completionHandler:(ARResourceCompletionHandler)completionHandler;

- (void)findLastWithOptions:(NSDictionary *)options completionHandler:(ARResourceCompletionHandler)completionHandler;

/*!
 * @brief Finds a single resource for a given identifier using the default URL.
 *
 * @par Ruby on Rails Comparison
 * Under the Rails' ActiveResource gem, this method appears as a private
 * method. Why not here? In Rails, you access the @c find_single(scope, options)
 * method indirectly as the default @c find(arguments) case when the first scope
 * argument does not match all, first, last or one (by symbol). Objective-C does
 * not offer so flexible a syntax. Consequently, this implementation folds the
 * find-scope interface into distinct methods: find all, find first, find last,
 * find one and find single. The scope argument resolves to the method @e
 * name. This approach carries advantages and disadvantages. It eliminates the
 * @c switch statement necessary to resolve the scope. But at the same stroke
 * eliminates the flexibility of parameterising the scope in cases where scope
 * is a dynamic argument.
 */
- (void)findSingleWithID:(NSNumber *)ID options:(NSDictionary *)options completionHandler:(ARResourceCompletionHandler)completionHandler;

/*!
 * @brief Finds a single resource from a one-off URL.
 * @details This method expects you to provide the one-off URL using the @ref
 * ARFromKey within the options dictionary. You must also specify query string
 * parameters using the @ref ARParamsKey within the options.
 */
- (void)findOneWithOptions:(NSDictionary *)options completionHandler:(ARResourceCompletionHandler)completionHandler;

@end
