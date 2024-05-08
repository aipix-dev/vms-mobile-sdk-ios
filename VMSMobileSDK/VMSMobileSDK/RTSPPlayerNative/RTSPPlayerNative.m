#import "RTSPPlayerNative.h"

@interface RTSPPlayerH264 () <SocketControlManagerDelegate, VideoDecoderDelegate, AudioDecoderDelegate>

@property (nonatomic, assign) NSString* url;
@property (nonatomic, assign) NSString* redirectUrl;
@property (nonatomic, assign) BOOL withAudio;
@property (nonatomic, assign) BOOL soundIsOn;
@property (nonatomic, assign) RTSPPlaybackSpeed speed;
@property (nonatomic, assign) RTSPPlayerState currentState;
@property (nonatomic, strong) SocketControlManager* socket;
@property (nonatomic, assign) SocketState currentSocketState;

@property (nonatomic, assign) long sdpStartDate;
@property (nonatomic, assign) long sdpSampleRate;
@property (nonatomic, assign) NSDate* frameDate;
@property (nonatomic, assign) long previousFrameTimestamp;
@property (nonatomic, assign) long currentFrameTimestamp;

@property (nonatomic, retain) id<VideoDecoderProtocol> videoDecoder;

@property (nonatomic, retain) AudioDecoder* audioDecoder;
@property (nonatomic, strong) AudioPlayer* audioPlayer;

@property (nonatomic, assign) int emptyFrameCouter;
@property (nonatomic, assign) NSDate* lastEmptyFrameTime;
@property (nonatomic, assign) int retryConnectCounter;

@property (nonatomic, assign) BOOL startToPlay;

@end

@implementation RTSPPlayerH264

#pragma mark - Init/Dealloc

- (id)initWithVideoUrl: (NSString *)url
             withAudio: (BOOL)withAudio
             soundIsOn: (BOOL)soundIsOn
                 speed: (RTSPPlaybackSpeed)speed
              delegate: (id<RTSPPlayerH264Delegate>)delegate
      didFailWithError: (out NSError **)error {
    
    if ((self = [super init])) {
        self.delegate = delegate;
        self.url = url;
        self.withAudio = withAudio;
        self.soundIsOn = soundIsOn;
        self.speed = speed;
        self.emptyFrameCouter = 0;
        self.startToPlay = NO;
        
        self.socket = [[SocketControlManager alloc] initWithURL: [self url]
                                                      withAudio: withAudio
                                                          speed: [self convertSpeed]
                                                       delegate: self];
        [self addObservers];
    }
    return self;
}

- (double)convertSpeed {
    switch (_speed) {
        case RTSPPlaybackSpeedSlow:
            return 0.5;
        case RTSPPlaybackSpeed1x:
            return 1;
        case RTSPPlaybackSpeed2x:
            return 2;
        case RTSPPlaybackSpeed4x:
            return 4;
        case RTSPPlaybackSpeed8x:
            return 8;
    }
}

- (void)dealloc {
    [_audioPlayer stop];
    [self removeObservers];
    [_socket disconnect];
    _socket = NULL;
}

#pragma mark - Observers

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decodingDidFail:) name:AVSampleBufferDisplayLayerFailedToDecodeNotification object:nil];
    
    if (@available(iOS 17.4, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startToPlay:) name:AVSampleBufferDisplayLayerReadyForDisplayDidChangeNotification object:nil];
    }
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - FailedToDecodeNotification handle

- (void)decodingDidFail:(NSNotification *)notification {
    NSDate *now = [NSDate date];
    
    if (_lastEmptyFrameTime && [now timeIntervalSinceDate: _lastEmptyFrameTime] < RTSP_PLAYER_EMPTY_FRAME_TIMER_THRASHHOLD) {
        _emptyFrameCouter++;
        if (_emptyFrameCouter > RTSP_PLAYER_EMPTY_FRAME_DISABLE_AUDIO_THRASHHOLD) {
            [_audioPlayer stop];
        }
        
        if (_emptyFrameCouter > RTSP_PLAYER_EMPTY_FRAME_STOP_PLAYER_THRASHHOLD) {
            if ([self.delegate respondsToSelector: @selector(rtspPlayerH264Error:error:)]) {
                [self playbackErrorDelegate: RTSPPlayerEmptyFramesError error: NULL];
            }
//                [self clearDecoder];
//                [self stop];
        }
    } else {
        _emptyFrameCouter = 0;
    }
    _lastEmptyFrameTime = now;
}

- (void) startToPlay:(NSNotification *)notification {
    if (!self->_startToPlay) {
        self->_startToPlay = YES;
        if ([self.delegate respondsToSelector: @selector(rtspPlayerH264StateChanged:)]) {
            [self.delegate rtspPlayerH264StateChanged: RTSPPlayerIsPlaying];
        }
    }
}

- (void)clearDecoder {
    [self->_audioPlayer stop];
    _audioDecoder = NULL;
    [self->_videoDecoder clearDecoder];
}

#pragma mark - Player Current State

- (RTSPPlayerState)currentPlayerState {
    return _currentState;
}

- (void)setPlayerState: (RTSPPlayerState)playerState {
    if (playerState != _currentState) {
        _currentState = playerState;
        if ([self.delegate respondsToSelector: @selector(rtspPlayerH264StateChanged:)]) {
            [self.delegate rtspPlayerH264StateChanged: playerState];
        }
    }
}

#pragma mark - Socket Current State

- (SocketState)currentSocketState {
    return _currentSocketState;
}

#pragma mark - Control

- (void)start {
    [_socket connect];
}

- (void)stop {
    [self clearDecoder];
    [_socket disconnect];
}

- (void)reset {
    [_socket reset];
}

- (BOOL)soundIsOn {
    return _withAudio && _soundIsOn;
}

- (void)setSoundOnOff: (BOOL)isOn {
    _soundIsOn = isOn;
    [_audioPlayer setSoundIsOn: isOn];
}

- (void)getScreenshot {
    [_videoDecoder needCurentImage];
}

#pragma mark - Init VideoDecoder

- (void)initVideoDecoderWithSDPInfo: (SDPInfo *)sdpInfo {
    switch (sdpInfo.videoTrack.videoCodec) {
        case VIDEO_CODEC_H264:
            _videoDecoder = [[VideoH264Decoder alloc ] initWithDelegate: self];
            break;
        case VIDEO_CODEC_H265:
            //            Uncomment this for 265 decode
            //            _videoDecoder = [[VideoH265Decoder alloc ] initWithDelegate: self];
            
            //Remove this for 265 decode
            _videoDecoder = NULL;
            [self playbackErrorDelegate: RTSPPlayerUnknownVideoFormat error: NULL];
            [self stop];
            break;
        default:
            _videoDecoder = NULL;
            [self playbackErrorDelegate: RTSPPlayerUnknownVideoFormat error: NULL];
            break;
    }
}

#pragma mark - Init AudioDecoder

- (void)initAudioDecoderAndPlayerWithSDPInfo: (SDPInfo *)sdpInfo {
    if (sdpInfo.audioTrack != NULL) {
        self.audioDecoder = [[AudioDecoder alloc] initWithConfig: sdpInfo];
        _audioDecoder.delegate = self;
        _audioPlayer = [[AudioPlayer alloc] initWithConfig: sdpInfo soundIsOn: _soundIsOn];
        
        if ([self.delegate respondsToSelector: @selector(rtspPlayerH264StateChanged:)]
            && _audioDecoder != NULL
            && _audioPlayer != NULL) {
            [self.delegate rtspPlayerH264StateChanged: RTSPPlayerIsHasSound];
        } else if ([self.delegate respondsToSelector: @selector(rtspPlayerH264StateChanged:)]) {
            [self.delegate rtspPlayerH264StateChanged: RTSPPlayerIsNoSound];
        }
    } else {
        if ([self.delegate respondsToSelector: @selector(rtspPlayerH264StateChanged:)]) {
            [self.delegate rtspPlayerH264StateChanged: RTSPPlayerIsNoSound];
        }
        [self playbackErrorDelegate: RTSPPlayerUnknownAudioFormat error: NULL];
    }
}

#pragma mark - Playback Date Calc

- (void)calculatePlaybackDate: (long)timeStamp {
    long calculatedTimeStamp = timeStamp * [self convertSpeed];
    if (calculatedTimeStamp > 0 && _sdpSampleRate > 0 && _currentFrameTimestamp > 0) {
        _previousFrameTimestamp = _currentFrameTimestamp;
        _currentFrameTimestamp = calculatedTimeStamp;
        double difference = _currentFrameTimestamp - _previousFrameTimestamp;
        double timeInterval = 1 / ((double)_sdpSampleRate / difference);
        _frameDate = [_frameDate dateByAddingTimeInterval: timeInterval];
    } else if (_previousFrameTimestamp == 0 && calculatedTimeStamp != 0) {
        _previousFrameTimestamp = calculatedTimeStamp;
    } else if (_currentFrameTimestamp == 0 && calculatedTimeStamp != 0 && _frameDate != NULL) {
        _currentFrameTimestamp = calculatedTimeStamp;
        double difference = _currentFrameTimestamp - _previousFrameTimestamp;
        double timeInterval = 1 / ((double)_sdpSampleRate / difference);
        _frameDate = [_frameDate dateByAddingTimeInterval: timeInterval];
    }
    if (!_frameDate && _sdpStartDate < 16725528000) {
        _frameDate = [NSDate dateWithTimeIntervalSince1970: _sdpStartDate];
    }
    if (_frameDate != NULL) {
        [self sendPlaybackDate: _frameDate];
    } else {
        [self sendPlaybackDate: NULL];
    }
}

- (void)sendPlaybackDate: (NSDate *)date {
    if ([self.delegate respondsToSelector: @selector(rtspPlayerH264CurrentPlaybackDate:)]) {
        [self.delegate rtspPlayerH264CurrentPlaybackDate: date];
    }
}

#pragma mark - Socket Manager Delegate

- (void)socketManagerDidChangeState:(SocketState)currentState {
    switch (currentState) {
        case SocketStateNotConnected:
        case SocketStateDoTeardown:
        case SocketStateDisconnected:
            [self setPlayerState: RTSPPlayerIsStopped];
            break;
        case SocketStateConnecting:
        case SocketStateConnected:
        case SocketStateDoOption:
        case SocketStateDoDescribe:
        case SocketStateDoSetupVideo:
        case SocketStateDoSetupAudio:
        case SocketStateDoPlay:
            [self setPlayerState: RTSPPlayerIsStarting];
            break;
        case SocketStatePlaying:
            [self setPlayerState: RTSPPlayerIsReadyToPlay];
            break;
    }
    if (_currentSocketState != currentState) {
        _currentSocketState = currentState;
        if ([self.delegate respondsToSelector: @selector(rtspPlayerH264SocketStateChanged:)]) {
            [self.delegate rtspPlayerH264SocketStateChanged: currentState];
        }
    }
}

- (void)socketManagerDidDisconnectWithError: (SocketError)socketError
                                      error: (NSError *)error {
    switch (socketError) {
        case SocketVideoPathInvalid:
            [self disconnectErrorDelegate: RTSPPlayerBrokenLinkError error: error];
            break;
        case SocketResponseTimeout:
            [self disconnectErrorDelegate: RTSPPlayerConnectTimeoutError error: error];
            break;
        case SocketResponseFailed:
            [self disconnectErrorDelegate: RTSPPlayerConnectResponseError error: error];
            break;
        case SocketResponseFailed204:
            [self disconnectErrorDelegate: RTSPPlayerNoContentError error: error];
        case SocketRTPPacketCorruptError:
            [self playbackErrorDelegate: RTSPPlayerCorruptPacketsError error: error];
            break;
        case SocketHasUnknownError:
            [self disconnectErrorDelegate: RTSPPlayerHasUnknownError error: error];
            break;
    }
}

- (void)disconnectErrorDelegate: (RTSPConnectionError)connectionError
                          error: (NSError *)error {
    
    if ([self.delegate respondsToSelector: @selector(rtspPlayerH264ConnectionError:error:)]) {
        [self.delegate rtspPlayerH264ConnectionError: connectionError error: error];
    }
}

- (void)playbackErrorDelegate: (RTSPPlaybackError)playbackError
                        error: (NSError *)error {
    
    if ([self.delegate respondsToSelector: @selector(rtspPlayerH264Error:error:)]) {
        [self.delegate rtspPlayerH264Error: playbackError error: error];
    }
}

- (void)socketManagerNeedConnectToNewUrl: (NSString *)url {
    if (!_redirectUrl) {
        [_socket disconnect];
        _socket.delegate = NULL;
        _socket = NULL;
        
        _redirectUrl = url;
        [self disconnectErrorDelegate: RTSPPlayerNeedConnectToNewUrlError error: NULL];
        self.socket = [[SocketControlManager alloc] initWithURL: url
                                                      withAudio: self.withAudio
                                                          speed: _speed
                                                       delegate: self];
        [self start];
    } else {
        [self disconnectErrorDelegate: RTSPPlayerBrokenLinkError error: NULL];
    }
}

- (void)socketManagerNeedTryToReconnectToUrl: (NSString *)url {
    if (_retryConnectCounter < RTSP_PLAYER_RETRY_CONNECT_THRASHHOLD) {
        _retryConnectCounter += 1;
        [_socket disconnect];
        _socket.delegate = NULL;
        _socket = NULL;
        
        [self disconnectErrorDelegate: RTSPPlayerNeedReconnect error: NULL];
        self.socket = [[SocketControlManager alloc] initWithURL: url
                                                      withAudio: self.withAudio
                                                          speed: _speed
                                                       delegate: self];
        [self start];
    } else {
        [self disconnectErrorDelegate: RTSPPlayerBrokenLinkError error: NULL];
    }
}

- (void)socketManagerHasSDPInfo:(SDPInfo *)sdpInfo {
    [self initVideoDecoderWithSDPInfo: sdpInfo];
    [self initAudioDecoderAndPlayerWithSDPInfo: sdpInfo];
    _sdpStartDate = sdpInfo.time - 2208988800;
    _sdpSampleRate = sdpInfo.videoTrack.sampleRate;
    [self calculatePlaybackDate: 0];
    if (sdpInfo.videoTrack.videoCodec) {
        [_videoDecoder setVPS: sdpInfo.videoTrack.vps
                       setSPS: sdpInfo.videoTrack.sps
                       setPPS: sdpInfo.videoTrack.pps];
    }
}

- (void)socketManagerHasVideoData: (NSMutableData *)videoData timestamp: (long)timeStamp {
    if (_videoDecoder) {
        [_videoDecoder decodeFrame: videoData];
        [self calculatePlaybackDate: timeStamp];
    }
}

- (void)socketManagerHasAudioData: (NSMutableData *)audioData {
    if (_audioDecoder) {
        [_audioDecoder decodeAudioData: audioData];
    }
}

- (void)socketManagerNeedResetAudio {
    if (_audioPlayer) {
        [_audioPlayer stop];
    }
}

#pragma mark - Video Decoder Delegate

- (void)decoderHasSampleBuffer: (CMSampleBufferRef)sampleBuffer {
//    if (self->_videoLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
//        NSLog(@"RTSP Player display layer rendering failed: %@", self->_videoLayer.error);
//        return;
//    }
    
    if ([self.delegate respondsToSelector: @selector(rtspPlayerH264HasSampleBuffer:)]) {
        [self.delegate rtspPlayerH264HasSampleBuffer: sampleBuffer];
    }
}

- (void)decoderHasScreenshot: (UIImage *)screenshot {
    if ([self.delegate respondsToSelector: @selector(rtspPlayerH264ScreenshotReady:)]) {
        [self.delegate rtspPlayerH264ScreenshotReady: screenshot];
    }
}

- (void) decoderHasIdrFrame {
    if (!self->_startToPlay) {
        self->_startToPlay = YES;
        if ([self.delegate respondsToSelector: @selector(rtspPlayerH264StateChanged:)]) {
            [self.delegate rtspPlayerH264StateChanged: RTSPPlayerIsPlaying];
        }
    }
}

#pragma mark - Audio Decoder Delegate

- (void)audioDecodeCallback:(NSData *)pcmData {
    [_audioPlayer playPCMData: pcmData];
}

@end
