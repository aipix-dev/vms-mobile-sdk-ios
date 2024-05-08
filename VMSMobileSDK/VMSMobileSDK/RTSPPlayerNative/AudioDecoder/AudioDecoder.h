#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SDPInfo.h"
#import "RTSPPlayerNativeConstants.h"

typedef struct {
    char * data;
    UInt32 size;
    UInt32 channelCount;
    AudioStreamPacketDescription packetDesc;
} AudioUserData;

@protocol AudioDecoderDelegate <NSObject>

- (void)audioDecodeCallback: (NSData *)pcmData;

@end

@interface AudioDecoder : NSObject

@property (nonatomic, weak) id<AudioDecoderDelegate> delegate;
@property (nonatomic, strong) SDPInfo *sdpInfo;
@property (nonatomic, assign) bool needStop;

- (instancetype)initWithConfig: (SDPInfo *)sdpInfo;

- (void)decodeAudioData: (NSData *)aacData;

@end
