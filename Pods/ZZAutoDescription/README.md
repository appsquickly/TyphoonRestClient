# ZZAutoDescription

[![Version](https://img.shields.io/cocoapods/v/ZZAutoDescription.svg?style=flat)](http://cocoadocs.org/docsets/ZZAutoDescription)
[![License](https://img.shields.io/cocoapods/l/ZZAutoDescription.svg?style=flat)](http://cocoadocs.org/docsets/ZZAutoDescription)
[![Platform](https://img.shields.io/cocoapods/p/ZZAutoDescription.svg?style=flat)](http://cocoadocs.org/docsets/ZZAutoDescription)

## About

`ZZAutoDescription` is a convenient set of categories for pretty printing your own objects, and also standard objects and collections from Objective-C.
Let's just make a quick comparison. Given the following set of data:

    NSArray *array = @[ @"Hello!",
                        @"123",
                        @(123),
                        @(123LL),
                        @(123.0f),
                        @(3.14159f),
                        @(3.14159),
                        @{@"id1": @[@1, @2, @3],
                          @"id2": @[@4, @5, @6]},
                        @"Good bye!" ];

here what standard `[array description]` will print:

    (
		"Hello!",
		123, 		// note that this is a string
		123, 		// this is an integer
		123, 		// this is long long
		123, 		// this is float
		"3.14159", 	// this is float
		"3.14159", 	// this is double
			{
			id1 =         (
				1,
				2,
				3
			);
			id2 =         (
				4,
				5,
				6
			);
		},
		"Good bye!"
	)

And what prints `ZZAutoDescription` for same data:

	[
	  "Hello!",
	  "123",    // string looks like a string
	  123,
	  123LL,    // long long is distinguishable from integer
	  123f,     // as a float
	  3.14159f,
	  3.14159,  // and as a double
	  {
		"id1" = [
		  1,
		  2,
		  3
		],
		"id2" = [
		  4,
		  5,
		  6
		]
	  },
	  "Good bye!"
	]

`ZZAutoDescription` also may automatically print properties of your objects.
See demo for more details (you may quickly see demo by using conventient `pod try` command, i.e. `pod try ZZAutoDescription`)

## Usage

	#import "NSObject+AutoDescription.h"

Given you have an object or a collection objects, just call:

	[object autoDescription]

or

	[collection autoDescription]

Also if you wish your object to be automatically autodescribed, add an `AUTO_DESCRIPTION` macro to implementation section of your object:

	@interface Product: NSObject
	<list of your properties>
	@end;

	@implementation Product
	AUTO_DESCRIPTION
	@end

It overrides `description` method so now you can use your object as usual with NSLog for example and it will be pretty-printed.

## Installation

ZZAutoDescription is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "ZZAutoDescription"

## Author

Ivan Zezyulya, zzautodescription@zoid.cc

## License

ZZAutoDescription is available under the MIT license. See the LICENSE file for more info.

