#import <Foundation/Foundation.h>

@interface AudioTrack : NSObject

@property (nonatomic, strong) NSString *request;
@property (nonatomic, assign) int payloadType;

@property (nonatomic, assign) int audioCodec;
@property (nonatomic) int sampleRateHz;
@property (nonatomic) int channels;
@property (nonatomic) NSString *mode;
@property (nonatomic) NSData *config;

@end
