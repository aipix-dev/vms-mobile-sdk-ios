#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoToolbox/VideoToolbox.h"

#import "SDPInfo.h"
#import "SocketControlManager.h"
#import "VideoDecoderProtocol.h"
#import "VideoH264Decoder.h"
#import "VideoH265Decoder.h"
#import "AudioDecoder.h"
#import "AudioPlayer.h"

typedef NS_ENUM(NSInteger, RTSPPlayerState) {
    RTSPPlayerIsStarting,
    RTSPPlayerIsReadyToPlay,
    RTSPPlayerIsPlaying,
    RTSPPlayerIsHasSound,
    RTSPPlayerIsNoSound,
    RTSPPlayerIsStopped
};

typedef NS_ENUM(NSInteger, RTSPConnectionError) {
    RTSPPlayerUnauthorizedError,
    RTSPPlayerBrokenLinkError,
    RTSPPlayerConnectResponseError,
    RTSPPlayerConnectTimeoutError,
    RTSPPlayerNeedConnectToNewUrlError,
    RTSPPlayerNeedReconnect,
    RTSPPlayerNoContentError,
    RTSPPlayerHasUnknownError
};

typedef NS_ENUM(NSInteger, RTSPPlaybackError) {
    RTSPPlayerUnknownVideoFormat,
    RTSPPlayerUnknownAudioFormat,
    RTSPPlayerCorruptPacketsError,
    RTSPPlayerContentTimeoutError,
    RTSPPlayerEmptyFramesError,
};

typedef NS_ENUM(NSInteger, RTSPPlaybackSpeed) {
    RTSPPlaybackSpeedSlow = - 2,
    RTSPPlaybackSpeed1x = 1,
    RTSPPlaybackSpeed2x = 2,
    RTSPPlaybackSpeed4x = 4,
    RTSPPlaybackSpeed8x = 8,
};

@protocol RTSPPlayerH264Delegate <NSObject>

- (void)rtspPlayerH264StateChanged: (RTSPPlayerState)state;
- (void)rtspPlayerH264SocketStateChanged: (SocketState)state;
- (void)rtspPlayerH264ConnectionError: (RTSPConnectionError)connectionError
                            error: (NSError *)error;
- (void)rtspPlayerH264Error: (RTSPPlaybackError)playbackError
                  error: (NSError *)error;
- (void)rtspPlayerH264HasSampleBuffer: (CMSampleBufferRef)sampleBuffer;
- (void)rtspPlayerH264CurrentPlaybackDate: (NSDate*)date;
- (void)rtspPlayerH264ScreenshotReady: (UIImage *)screenshot;

@end

@interface RTSPPlayerH264: NSObject

@property (nonatomic, weak) id<RTSPPlayerH264Delegate> delegate;

- (id)initWithVideoUrl: (NSString *)url
//                       videoView: (UIView *)videoView
                       withAudio: (BOOL)withAudio //use flag if camera has sound, its not about mute/unmute
                       soundIsOn: (BOOL)soundIsOn //use flag if audio is enabled by default
                           speed: (RTSPPlaybackSpeed)speed
                        delegate: (id<RTSPPlayerH264Delegate>)delegate
                didFailWithError: (out NSError **)error;

//- (void)resetVideoLayerOnView: (UIView *)videoView;

- (void)start;
- (void)stop;
- (void)reset;

- (SocketState)currentSocketState;
- (RTSPPlayerState)currentPlayerState;

- (BOOL)soundIsOn;
- (void)setSoundOnOff: (BOOL)isOn;

- (void)getScreenshot;

@end
