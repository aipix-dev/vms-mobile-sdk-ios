#import <Foundation/Foundation.h>
#import "ParsableByteArray.h"
#import "ParsableBitArray.h"

#define AUDIO_DECODER_MODE_LBR 0
#define AUDIO_DECODER_MODE_HBR 1
#define AUDIO_DECODER_NUM_BITS_AU_SIZES ((int[2]){6, 13})
#define AUDIO_DECODER_NUM_BITS_AU_INDEX ((int[2]){2, 3})

@interface AudioRTPParser : NSObject

@property (nonatomic, strong) ParsableBitArray *headerScratchBits;
@property (nonatomic, strong) ParsableByteArray *headerScratchBytes;
@property (nonatomic, assign) int aacMode;
@property (nonatomic, assign) int numBitsAuSize;
@property (nonatomic, assign) int numBitsAuIndex;

- (instancetype)initWithAacMode: (NSString *)aacMode;
- (NSMutableData *)processRtpPacketAndGetSample: (uint8_t *)data length: (int)length;

@end
