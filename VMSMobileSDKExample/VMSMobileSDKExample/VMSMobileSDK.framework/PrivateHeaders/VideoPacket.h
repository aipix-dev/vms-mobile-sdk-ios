#import <Foundation/Foundation.h>

@interface VideoPacket: NSObject

@property (nonatomic, strong) NSMutableData *frame;
@property (nonatomic, assign) long timeStamp;

@end
