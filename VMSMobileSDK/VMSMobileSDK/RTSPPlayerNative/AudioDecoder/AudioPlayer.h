#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "SDPInfo.h"
#import "RTSPPlayerNativeConstants.h"

typedef struct AudioPlayerState {
    AudioStreamBasicDescription         dataFormat;
    AudioQueueRef                       queue;
    AudioQueueBufferRef                 buffers[AUDIO_PLAYER_NUMBERS_OF_BUFFERS];
    AudioStreamPacketDescription        *packetDescs;
} AudioPlayerState;

@interface AudioPlayer : NSObject

@property (nonatomic, assign) AudioPlayerState playerState;
@property (nonatomic, strong) SDPInfo *sdpInfo;
@property (nonatomic, assign) BOOL isBeginPlaying;
@property (nonatomic, assign) BOOL soundIsOn;

- (instancetype)initWithConfig: (SDPInfo *)sdpInfo
                     soundIsOn: (BOOL)soundIsOn;

- (void)playPCMData: (NSData *)data;
- (void)setVolume: (Float32)gain;
- (void)stop;
- (void)play;
- (void)dispose;

@end
