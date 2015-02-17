//
//  NSObject+AutoDescription.h
//

#import <Foundation/Foundation.h>

@interface NSObject (AutoDescription)

- (NSString *) autoDescription;

/// Implement the following method to fine-control which properties should be printed:
///- (BOOL) shouldAutoDescribeProperty:(NSString *)propertyName;

/// Implement the following method to control whether properties of super class(es)
/// should be printed:
//- (BOOL) shouldAutoDescribePropertiesOfSuperClass:(Class)superClass;

@end

#define AUTO_DESCRIPTION            \
- (NSString *) description          \
{                                   \
    return [self autoDescription];  \
}                                   \
- (BOOL) autoDescriptionEnabled     \
{                                   \
    return YES;                     \
}
