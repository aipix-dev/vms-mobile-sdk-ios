#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "SDPInfo.h"
#import "RTSPPlayerNativeConstants.h"

#define RTSP_VERSION (@"RTSP/1.0")
#define RTSP_OK_STATUS (@"RTSP/1.0 200 OK")

typedef NS_ENUM(NSInteger, SocketState) {
    SocketStateNotConnected = 0,
    SocketStateConnecting,
    SocketStateConnected,
    SocketStateDoOption,
    SocketStateDoDescribe,
    SocketStateDoSetupVideo,
    SocketStateDoSetupAudio,
    SocketStateDoPlay,
    SocketStateDoTeardown,
    SocketStatePlaying,
    SocketStateDisconnected,
};

typedef NS_ENUM(NSInteger, SocketError) {
    SocketVideoPathInvalid = 1710241111,
    SocketResponseTimeout,
    SocketResponseFailed,
    SocketResponseFailed204,
    SocketRTPPacketCorruptError,
    SocketHasUnknownError,
};

@protocol SocketControlManagerDelegate <NSObject>

@optional
- (void)socketManagerDidChangeState: (SocketState)currentState;
- (void)socketManagerDidDisconnectWithError: (SocketError)socketError
                                      error: (NSError *)error;
- (void)socketManagerNeedConnectToNewUrl: (NSString *)url;
- (void)socketManagerNeedTryToReconnectToUrl: (NSString *)url;
- (void)socketManagerHasSDPInfo: (SDPInfo *)sdpInfo;
- (void)socketManagerHasVideoData: (NSMutableData *)videoData
                        timestamp: (long)timeStamp;
- (void)socketManagerHasAudioData: (NSMutableData *)audioData;
- (void)socketManagerNeedResetAudio;

@end

@interface SocketControlManager : NSObject

- (instancetype)initWithURL: (NSString *)url
                  withAudio: (BOOL)withAudio
                      speed: (double)speed
                   delegate: (id<SocketControlManagerDelegate>)delegate;

@property (nonatomic, weak) id<SocketControlManagerDelegate> delegate;

- (SocketState)getState;
- (void)connect;
- (void)disconnect;
- (void)reset;

@end
