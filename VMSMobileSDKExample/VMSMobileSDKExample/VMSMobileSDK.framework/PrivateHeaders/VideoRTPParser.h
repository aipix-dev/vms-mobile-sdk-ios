#import <Foundation/Foundation.h>

#define NAL_UNIT_TYPE 0x1F
#define NAL_UNIT_PACK_FLAG 0xC0

#define NAL_UNIT_TYPE_STAP_A 24
#define NAL_UNIT_TYPE_STAP_B 25
#define NAL_UNIT_TYPE_MTAP16 26
#define NAL_UNIT_TYPE_MTAP24 27
#define NAL_UNIT_TYPE_FU_A 28
#define NAL_UNIT_TYPE_FU_B 29

#define NAL_UNIT_START_PACKET 0x80
#define NAL_UNIT_MIDDLE_PACKET 0x00
#define NAL_UNIT_END_PACKET 0x40

@interface VideoRtpParser : NSObject {
    NSMutableArray<NSMutableData *> *dataBuffer;
    NSMutableData *nalUnit;
    BOOL nalEndFlag;
    NSUInteger bufferLength;
    NSUInteger packetNum;
}

- (NSMutableData *)processRtpPacketAndGetNalUnit: (uint8_t *)data length: (int)length;

@end
