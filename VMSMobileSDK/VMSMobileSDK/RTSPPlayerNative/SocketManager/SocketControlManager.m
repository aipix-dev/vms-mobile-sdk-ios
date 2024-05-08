#import <Foundation/Foundation.h>
#import "SocketControlManager.h"
#import "SocketControlHelper.h"
#import "RTPData.h"

@interface SocketControlManager() <RTPDataDelegate, GCDAsyncSocketDelegate>

@property (strong, nonatomic) GCDAsyncSocket *socket;
@property (nonatomic, assign) SocketState currentState;

@property (copy, nonatomic) NSString *url;
@property (copy, nonatomic) NSString *host;
@property (assign, nonatomic) int16_t port;
@property (copy, nonatomic) NSString *sessionID;
@property (copy, nonatomic) NSString *authToken;
@property (assign, nonatomic) NSInteger seq;

@property (strong, nonatomic) NSMutableDictionary<NSString *, NSString *> *headers;
@property (assign, nonatomic) NSInteger status;
@property (assign, nonatomic) NSString* currentUrl;
@property (assign, nonatomic) NSString* redirectUrl;
@property (strong, nonatomic) RTPData *rtpData;
@property (strong, nonatomic) SDPInfo *sdpInfo;
@property (assign, nonatomic) double speed;

@property (nonatomic, strong) dispatch_queue_t rtpDataQueue;

@end

@implementation SocketControlManager

#pragma mark - Init/Dealloc

- (instancetype)initWithURL: (NSString *)url
                  withAudio: (BOOL)withAudio
                      speed: (double)speed
                   delegate: (id<SocketControlManagerDelegate>)delegate {
    if (self = [super init]) {
        self.currentUrl = url;
        self.speed = speed;
        self.delegate = delegate;
        [self initSocketWithUrl: url];
        self.rtpDataQueue = dispatch_queue_create("rtp.packet.parsing.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)initSocketWithUrl: (NSString *)url {
    
    if (![self checkAndGetVideoIPAndPort: url]) {
        if ([_delegate respondsToSelector: @selector(socketManagerDidDisconnectWithError:error:)]) {
            [_delegate socketManagerDidDisconnectWithError: SocketVideoPathInvalid error: NULL];
        }
        return;
    }
    
    if (self.socket && self.socket.isConnected) {
        [self disconnect];
    }
    
    dispatch_queue_t delegateQueue = dispatch_queue_create([NSStringFromClass([self class]) UTF8String], DISPATCH_QUEUE_PRIORITY_DEFAULT);
    
    self.socket = [[GCDAsyncSocket alloc]
                   initWithDelegate: self
                   delegateQueue: delegateQueue
                   socketQueue: nil];
    
    self.socket.delegate = self;
}

- (void)dealloc {
    [self stopSocket];
}

#pragma mark - Control

- (void)stopSocket {
    [_socket disconnect];
    [_rtpData closeStream];
    _socket = NULL;
    _sdpInfo = NULL;
    _rtpData = NULL;
    _sdpInfo = NULL;
}

- (void)reset {
    [_socket disconnect];
    _seq = 0;
    _sdpInfo = NULL;
    [_rtpData closeStream];
    _rtpData = NULL;
    [self connect];
}

- (void)setCurrentState:(SocketState)newState {
    _currentState = newState;
    [self handleStateChanged];
}

- (BOOL)checkAndGetVideoIPAndPort:(NSString *)videoPath {
    NSURL *uri = [NSURL URLWithString:videoPath];
    NSNumber *port = SOCKET_DEFAULT_PORT;
    
    if (uri.port) port = uri.port;
    
    if (uri == NULL || uri.host == NULL) return NO;
    
    _host = uri.host;
    _port = port.longLongValue;
    _url = videoPath;
    return YES;
}

#pragma mark - State Control

- (void)connect {
    [self setCurrentState: SocketStateConnecting];
}

- (void)disconnect {
    [self setCurrentState: SocketStateDisconnected];
}

- (SocketState)getState {
    return _currentState;
}

- (void)canDoNextStep {
    switch (self.currentState) {
        case SocketStateDoOption:
            [self setCurrentState: SocketStateDoDescribe];
            break;
        case SocketStateDoDescribe:
            [self setCurrentState: SocketStateDoSetupVideo];
            break;
        case SocketStateDoSetupVideo:
            (_sdpInfo.audioTrack == NULL)
            ? [self setCurrentState: SocketStateDoPlay]
            : [self setCurrentState: SocketStateDoSetupAudio];
            break;
        case SocketStateDoSetupAudio:
            [self setCurrentState: SocketStateDoPlay];
            break;
        case SocketStateDoPlay:
            [self setCurrentState: SocketStatePlaying];
            break;
        default:
            break;
    }
}

- (void)handleStateChanged {
    switch (self.currentState) {
        case SocketStateConnecting:
            [_socket connectToHost: _host
                            onPort: _port
                       withTimeout: SOCKET_DEFAULT_TIMEOUT
                             error: nil];
            break;
        case SocketStateConnected:
            [self setCurrentState: SocketStateDoOption];
            break;
        case SocketStateDoOption:
        case SocketStateDoDescribe:
        case SocketStateDoSetupVideo:
        case SocketStateDoSetupAudio:
        case SocketStateDoPlay:
        case SocketStateDoTeardown:
            _seq++;
            [self sendSocketMessage];
            break;
        case SocketStateDisconnected:
            [self stopSocket];
        default:
            break;
    }
    if ([_delegate respondsToSelector: @selector(socketManagerDidChangeState:)]) {
        [_delegate socketManagerDidChangeState: _currentState];
    }
}

#pragma mark - Send commands

- (void)sendSocketMessage {
    NSMutableString *message = [SocketControlHelper getMessageForState: _currentState
                                                                   url: _url
                                                                   seq: _seq
                                                             sessionID: _sessionID
                                                             authToken: _authToken];
    NSData *data = [message dataUsingEncoding: NSUTF8StringEncoding];
    [_socket writeData: data withTimeout: -1 tag: 0];
}

#pragma mark - Response Handle

- (void)hasResponseData: (NSData *)data {
    if (_currentState == SocketStatePlaying) {
        [self didRecieveNewStream: data];
    } else {
        [self recieveNewResponseData: data];
    }
}

#pragma mark - Socket Response Handling/Parsing

- (void)recieveNewResponseData:(NSData *)newData {
    
    @synchronized(self) {
        _status = [SocketControlHelper getResponseStatusCode: newData];
        _headers = [SocketControlHelper getResponseHeaders: newData];
        _redirectUrl = [SocketControlHelper getResponseLocation: newData];
        
        NSLog(@"Current response: %@", [SocketControlHelper getCurrentStepName: _currentState]);
        NSLog(@"Response status code: %ld", (long)_status);
        NSLog(@"Response data: %@", [SocketControlHelper getStringFromData: newData]);
        
        switch (_status) {
            case 0:
                if([_delegate respondsToSelector: @selector(socketManagerDidDisconnectWithError:error:)] && _currentUrl != NULL) {
                    [_delegate socketManagerNeedTryToReconnectToUrl: _currentUrl];
                }
                [self disconnect];
                return;
            case 200:
                break;
            case 204:
                if([_delegate respondsToSelector: @selector(socketManagerDidDisconnectWithError:error:)]) {
                    [_delegate socketManagerDidDisconnectWithError: SocketResponseFailed204 error: NULL];
                }
                [self disconnect];
                return;
            case 302:
                if([_delegate respondsToSelector: @selector(socketManagerDidDisconnectWithError:error:)] && _redirectUrl != NULL) {
                    [_delegate socketManagerNeedConnectToNewUrl: _redirectUrl];
                }
                return;
            case 403:
                if([_delegate respondsToSelector: @selector(socketManagerDidDisconnectWithError:error:)]) {
                    [_delegate socketManagerDidDisconnectWithError: SocketVideoPathInvalid error: NULL];
                }
                [self disconnect];
                return;
            default:
                if([_delegate respondsToSelector: @selector(socketManagerDidDisconnectWithError:error:)]) {
                    [_delegate socketManagerDidDisconnectWithError: SocketResponseFailed error: NULL];
                }
                [self disconnect];
                return;
        }
        if (_currentState == SocketStateDoDescribe) {
            NSInteger contentLength = [SocketControlHelper getHeaderContentLength: _headers];
            NSString *response = [SocketControlHelper getStringFromData: newData];
            if (contentLength > 0) {
                _sdpInfo = [SDPInfo parseSDPInfoFromParams: response];
                _sessionID = _sdpInfo.session;
                if ([_delegate respondsToSelector: @selector(socketManagerHasSDPInfo:)]) {
                    [_delegate socketManagerHasSDPInfo: _sdpInfo];
                }
            }
        }
        [self canDoNextStep];
    }
}

#pragma mark - Socket RTP Data Handling/Parsing

- (void)didRecieveNewStream: (NSData *)newStream {
    @autoreleasepool {
        dispatch_async(_rtpDataQueue, ^{
            if (self->_currentState != SocketStateDisconnected) {
                if (!self->_rtpData) {
                    self->_rtpData = [[RTPData alloc] initWithSdpInfo: self->_sdpInfo
                                                                speed: self->_speed
                                                             delegate: self];
                }
                [self->_rtpData openStreamWithData: newStream];
            }
        });
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket: (GCDAsyncSocket *)sock didConnectToHost: (NSString *)host port: (uint16_t)port {
    [_socket readDataWithTimeout: SOCKET_DEFAULT_TIMEOUT tag: 0];
    [self setCurrentState: SocketStateConnected];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    switch (err.code) {
        case GCDAsyncSocketReadTimeoutError:
        case GCDAsyncSocketWriteTimeoutError:
        case GCDAsyncSocketConnectTimeoutError:
            if ([_delegate respondsToSelector: @selector(socketManagerDidDisconnectWithError:error:)]) {
                [_delegate socketManagerDidDisconnectWithError: SocketResponseTimeout error: err];
            }
            break;
        case GCDAsyncSocketClosedError:
            if([_delegate respondsToSelector: @selector(socketManagerDidDisconnectWithError:error:)] && _currentUrl != NULL) {
                [_delegate socketManagerNeedTryToReconnectToUrl: _currentUrl];
            }
            [self disconnect];
            return;
        default:
            if ([_delegate respondsToSelector: @selector(socketManagerDidDisconnectWithError:error:)] && _currentState != SocketStateDisconnected) {
                NSLog(@"SOCKET ERROR IS - %@, %ld", err.localizedDescription, (long)err.code);
                [_delegate socketManagerDidDisconnectWithError: SocketHasUnknownError error: err];
            }
            break;
    }
    [self setCurrentState: SocketStateDisconnected];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    [_socket readDataWithTimeout: SOCKET_DEFAULT_TIMEOUT tag: 0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [_socket readDataWithTimeout: SOCKET_DEFAULT_TIMEOUT tag: 0];
    [self hasResponseData: data];
}

#pragma mark - RTPDataDelegate

- (void)rtpPacketHasVideoData: (NSMutableData *)videoData timestamp: (long)timeStamp {
    if ([_delegate respondsToSelector:@selector(socketManagerHasVideoData:timestamp:)]) {
        [_delegate socketManagerHasVideoData: videoData timestamp: timeStamp];
    }
}

- (void)rtpPacketHasAudioData: (NSMutableData *)audioData {
    if ([_delegate respondsToSelector:@selector(socketManagerHasAudioData:)]) {
        [_delegate socketManagerHasAudioData: audioData];
    }
}

- (void)rtpPacketNeedResetAudio {
    if ([_delegate respondsToSelector:@selector(socketManagerNeedResetAudio)]) {
        [_delegate socketManagerNeedResetAudio];
    }
}

- (void)rtpPacketIsCorrupt {
    if ([_delegate respondsToSelector:@selector(socketManagerDidDisconnectWithError:error:)]) {
        [_delegate socketManagerDidDisconnectWithError: SocketRTPPacketCorruptError error: NULL];
    }
}

@end
