#import <Foundation/Foundation.h>
#import "SDPInfo.h"
#import "RTPHeader.h"
#import "VideoPacket.h"
#import "VideoRTPParser.h"
#import "AudioRTPParser.h"
#import "RTSPPlayerNative.h"
#import "RTSPPlayerNativeConstants.h"

#define HEADER_SIZE 4
#define RTP_HEADER_SIZE 12

@protocol RTPDataDelegate <NSObject>

- (void)rtpPacketHasVideoData: (NSMutableData *)videoData
                    timestamp: (long) timeStamp;
- (void)rtpPacketHasAudioData: (NSMutableData *)audioData;
- (void)rtpPacketNeedResetAudio;
- (void)rtpPacketIsCorrupt;

@end

@interface RTPData : NSObject  <NSStreamDelegate>

@property (nonatomic, readwrite) NSInputStream *rtpStream;
@property (nonatomic, readwrite) NSMutableData *readBuffer;
@property (nonatomic, assign) NSUInteger readBufferLength;
@property (nonatomic, strong) RTPHeader *header;
@property (nonatomic, strong) SDPInfo *sdpInfo;
@property (nonatomic, assign) double fps;
@property (nonatomic, assign) double calculatedFps;
@property (nonatomic, assign) double speed;

@property (nonatomic, strong) VideoRtpParser *videoParser;
@property (nonatomic, strong) AudioRTPParser *audioParser;

@property (nonatomic, weak) id<RTPDataDelegate> delegate;

- (instancetype)initWithSdpInfo: (SDPInfo *)sdpInfo
                          speed: (double)speed
                       delegate: (id<RTPDataDelegate>)delegate;

- (void)openStreamWithData: (NSData *)rtpData;
- (void)hasNewData: (NSData *)rtpData;
- (void)closeStream;

@end
