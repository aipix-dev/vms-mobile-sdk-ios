#import "AudioPlayer.h"

@implementation AudioPlayer

static void AudioQueueOutCallback(void * inUserData,
                                  AudioQueueRef inAQ,
                                  AudioQueueBufferRef inBuffer) {
    AudioQueueFreeBuffer(inAQ, inBuffer);
}

- (instancetype)initWithConfig: (SDPInfo *)sdpInfo soundIsOn: (BOOL)soundIsOn {
    self = [super init];
    if (self = [super init]) {
        _sdpInfo = sdpInfo;
        AudioStreamBasicDescription dataFormat = {0};
        dataFormat.mSampleRate = (Float64)_sdpInfo.audioTrack.sampleRateHz;
        dataFormat.mChannelsPerFrame = (UInt32)_sdpInfo.audioTrack.channels;
        dataFormat.mFormatID = kAudioFormatLinearPCM;
        dataFormat.mFormatFlags = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked);
        dataFormat.mFramesPerPacket = 1;
        dataFormat.mBitsPerChannel = 16;
        dataFormat.mBytesPerFrame = dataFormat.mBitsPerChannel / 8 *dataFormat.mChannelsPerFrame;
        dataFormat.mBytesPerPacket = dataFormat.mBytesPerFrame * dataFormat.mFramesPerPacket;
        dataFormat.mReserved =  0;
        
        AudioPlayerState state = {0};
        state.dataFormat = dataFormat;
        _playerState = state;
        
        [self setupSession];
        [self setupAudioQueueAndBuffers];
        
        self.isBeginPlaying = NO;
        self.soundIsOn = soundIsOn;
    }
    return self;
}

- (BOOL)setupSession {
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &error];
    if (error) {
        NSLog(@"Error: audioQueue player AVAudioSession error, error: %@", error);
        return NO;
    }
    NSUInteger options = 0;
    options |= AVAudioSessionCategoryOptionDefaultToSpeaker
            | AVAudioSessionCategoryOptionAllowBluetooth
            | AVAudioSessionCategoryOptionAllowBluetoothA2DP;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord 
                                            mode: AVAudioSessionModeDefault
                                         options: options
                                           error: &error];
    if (error) {
        NSLog(@"Error: audioQueue player AVAudioSession error, error: %@", error);
        return NO;
    }
    return YES;
}

- (BOOL)setupAudioQueueAndBuffers {
    OSStatus status = AudioQueueNewOutput(&_playerState.dataFormat,
                                          AudioQueueOutCallback,
                                          (__bridge void *)self,
                                          NULL,
                                          NULL,
                                          0,
                                          &_playerState.queue);
    if (status != noErr) {
        NSError *error = [[NSError alloc] initWithDomain: NSOSStatusErrorDomain code: status userInfo: nil];
        NSLog(@"Error: AudioQueue create error = %@", [error description]);
        return NO;
    }
    
    AudioQueueSetParameter(_playerState.queue, kAudioQueueParam_Volume, 1);

    for (int i = 0; i < AUDIO_PLAYER_NUMBERS_OF_BUFFERS; i++) {
        AudioQueueAllocateBuffer(_playerState.queue,
                                 AUDIO_PLAYER_MIN_SIZE_PER_FRAME,
                                 &_playerState.buffers[i]);
    }
    return YES;
}

- (void)dealloc {
    if(_playerState.queue) {
        AudioQueueStop(_playerState.queue, true);
    }
    
    for(size_t i = 0; i < AUDIO_PLAYER_NUMBERS_OF_BUFFERS; i++) {
        if(_playerState.buffers[i]) {
            AudioQueueFreeBuffer(_playerState.queue, _playerState.buffers[i]);
            _playerState.buffers[i] = NULL;
        }
    }
    
    if(_playerState.queue) {
        AudioQueueDispose(_playerState.queue, true);
        _playerState.queue = NULL;
    }
}

- (void)checkAndRestartAudioQueueIfNeeded {
    UInt32 isRunning = 0;
    UInt32 size = sizeof(isRunning);
    OSStatus status = AudioQueueGetProperty(_playerState.queue, kAudioQueueProperty_IsRunning, &isRunning, &size);
    
    if (status != noErr) {
        NSLog(@"Error checking Audio Queue status: %d", (int)status);
        [self handleAudioQueueError:status];
    } else if (isRunning == 0) {
        NSLog(@"Audio Queue stopped unexpectedly. Attempting to restart.");
        [self setupAudioQueueAndBuffers];
        [self play];
    }
}

- (void)handleAudioQueueError:(OSStatus)error {
    NSLog(@"Audio Queue Error: %d", (int)error);
    [self dispose];
    [self setupAudioQueueAndBuffers];
}

- (void)playPCMData: (NSData *)data {
    if (_soundIsOn) {
        AudioQueueBufferRef inBuffer;
        if (self != NULL && data != NULL) {
            @synchronized (self) {
                OSStatus ret = AudioQueueAllocateBuffer(_playerState.queue,
                                         AUDIO_PLAYER_MIN_SIZE_PER_FRAME,
                                         &inBuffer);
                if (ret == noErr) {
                    memcpy(inBuffer->mAudioData, data.bytes, data.length);
                    inBuffer->mAudioDataByteSize = (UInt32)data.length;
                } else {
                    [self handleAudioQueueError:ret];
                    return;
                }
                OSStatus status = AudioQueueEnqueueBuffer(_playerState.queue,
                                                          inBuffer,
                                                          0,
                                                          NULL);
                if (status == noErr) {
                        [self checkAndRestartAudioQueueIfNeeded];
                } else {
                        NSLog(@"Error adding buffer to queue: %d", (int)status);
                        [self handleAudioQueueError:status];
                    }
            }
            [self play];
        }
    }
}

- (void)dispose {
    @synchronized (self) {
        if (_playerState.queue != NULL) {
            AudioQueueStop(_playerState.queue, YES);
            AudioQueueDispose(_playerState.queue, YES);
        }
        _isBeginPlaying = NO;
    }
}

- (void)setSoundIsOn: (BOOL)soundIsOn {
    _soundIsOn = soundIsOn;
    if (!soundIsOn && _playerState.queue != NULL) {
        AudioQueueStop(_playerState.queue, TRUE);
        AudioQueueDispose(_playerState.queue, true);
        _isBeginPlaying = NO;
    } else {
        [self setupAudioQueueAndBuffers];
    }
}

- (void)stop {
    [self dispose];
}

- (void)play {
    if (_soundIsOn) {
        if (!_isBeginPlaying) {
            AudioQueueStart(_playerState.queue, NULL);
        } else {
            AudioQueueFlush(_playerState.queue);
            AudioQueueStart(_playerState.queue, NULL);
        }
        _isBeginPlaying = YES;
    }
}

@end
