#import <Foundation/Foundation.h>

@interface VideoTrack : NSObject

@property (nonatomic, strong) NSString *request;
@property (nonatomic, assign) int payloadType;

@property (nonatomic, assign) int videoCodec;
@property (nonatomic) NSUInteger sampleRate;
@property (nonatomic) NSUInteger frameRate;
@property (nonatomic) NSMutableData *vps;
@property (nonatomic) NSUInteger vpsSize;
@property (nonatomic) NSMutableData *sps;
@property (nonatomic) NSUInteger spsSize;
@property (nonatomic) NSMutableData *pps;
@property (nonatomic) NSUInteger ppsSize;

@end
