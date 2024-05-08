#import <Foundation/Foundation.h>

@interface RTPHeader : NSObject

@property (nonatomic, assign) int version;
@property (nonatomic, assign) int padding;
@property (nonatomic, assign) int extension;
@property (nonatomic, assign) int cc;
@property (nonatomic, assign) int marker;
@property (nonatomic, assign) int payloadType;
@property (nonatomic, assign) int sequenceNumber;
@property (nonatomic, assign) long timeStamp;
@property (nonatomic, assign) long ssrc;
@property (nonatomic, assign) int payloadSize;

+ (RTPHeader *)parseData: (uint8_t *)header packetSize: (int)packetSize;

@end
