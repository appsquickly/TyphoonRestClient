

#import <Foundation/Foundation.h>

@interface Issue : NSObject

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *projectName;
@property (nonatomic, strong) NSString *authorName;
@property (nonatomic, strong) NSString *statusText;

@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *descriptionText;

@property (nonatomic, strong) NSDate *created;
@property (nonatomic, strong) NSDate *updated;

@property (nonatomic, strong) NSNumber *doneRatio;

@end
