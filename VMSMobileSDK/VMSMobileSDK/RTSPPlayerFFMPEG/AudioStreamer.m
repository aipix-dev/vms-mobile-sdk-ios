#import "AudioStreamer.h"
#import "RTSPPlayerFFMPEG.h"

void audioQueueOutputCallback(void *inClientData, AudioQueueRef inAQ,
  AudioQueueBufferRef inBuffer);
void audioQueueIsRunningCallback(void *inClientData, AudioQueueRef inAQ,
  AudioQueuePropertyID inID);

void audioQueueOutputCallback(void *inClientData, AudioQueueRef inAQ,
  AudioQueueBufferRef inBuffer) {

    AudioStreamer *audioController = (__bridge AudioStreamer*)inClientData;
    [audioController audioQueueOutputCallback:inAQ inBuffer:inBuffer];
}

void audioQueueIsRunningCallback(void *inClientData, AudioQueueRef inAQ,
  AudioQueuePropertyID inID) {

    AudioStreamer *audioController = (__bridge AudioStreamer*)inClientData;
    [audioController audioQueueIsRunningCallback];
}

@interface AudioStreamer ()
@property (nonatomic, assign) RTSPPlayerFFMPEG *streamer;
@property (nonatomic, assign) AVCodecContext *audioCodecContext;
@end

@implementation AudioStreamer

@synthesize streamer = _streamer;
@synthesize audioCodecContext = _audioCodecContext;

- (id)initWithStreamer:(RTSPPlayerFFMPEG*)streamer {
    if (self = [super init]) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        _streamer = streamer;
        _audioCodecContext = _streamer._audioCodecContext;
    }
    
    return  self;
}


- (IBAction)playAudio:(UIButton*)sender
{
    [self _startAudio];
}

- (IBAction)pauseAudio:(UIButton*)sender
{
    if (started_) {
      state_ = AUDIO_STATE_PAUSE;

      AudioQueuePause(audioQueue_);
      AudioQueueReset(audioQueue_);
    }
}

- (void)_startAudio
{
    NSLog(@"ready to start audio");
    if (started_) {
        AudioQueueStart(audioQueue_, NULL);
    } else {
        [self createAudioQueue] ;
        [self startQueue];
    }

    for (NSInteger i = 0; i < kNumAQBufs; ++i) {
      [self enqueueBuffer:audioQueueBuffer_[i]];
    }

    state_ = AUDIO_STATE_PLAYING;
}

- (void)_stopAudio
{
    if (started_) {
        AudioQueueStop(audioQueue_, YES);
        startedTime_ = 0.0;
        state_ = AUDIO_STATE_STOP;
        finished_ = NO;
    }
}

- (BOOL)createAudioQueue
{
    state_ = AUDIO_STATE_READY;
    finished_ = NO;

    if (decodeLock_) {
        [decodeLock_ unlock];
        decodeLock_ = nil;
    }
    
    decodeLock_ = [[NSLock alloc] init];
    
    audioStreamBasicDesc_.mFormatID = -1;
    audioStreamBasicDesc_.mSampleRate = _audioCodecContext->sample_rate;

    if (audioStreamBasicDesc_.mSampleRate < 1) {
        audioStreamBasicDesc_.mSampleRate = 32000;
    }

    audioStreamBasicDesc_.mFormatFlags = 0;
    
    switch (_audioCodecContext->codec_id) {
        case AV_CODEC_ID_AAC:
        {
            audioStreamBasicDesc_.mFormatID = kAudioFormatMPEG4AAC;
            audioStreamBasicDesc_.mFormatFlags = kMPEG4Object_AAC_LC;
            audioStreamBasicDesc_.mSampleRate = _audioCodecContext->sample_rate;
            audioStreamBasicDesc_.mChannelsPerFrame = _audioCodecContext->ch_layout.nb_channels;
            audioStreamBasicDesc_.mBitsPerChannel = 0;
            audioStreamBasicDesc_.mFramesPerPacket =_audioCodecContext->frame_size;
            audioStreamBasicDesc_.mBytesPerPacket = 0;
            audioStreamBasicDesc_.mBytesPerFrame = 0;
            audioStreamBasicDesc_.mReserved = 0;
            NSLog(@"audio format %s is supported", _audioCodecContext->codec_descriptor->name);
            
            break;
        }

        default:
        {
            NSLog(@"Error: audio format '%s' (%d) is not supported", _audioCodecContext->codec_descriptor->name, _audioCodecContext->codec_id);
            audioStreamBasicDesc_.mFormatID = kAudioFormatAC3;
            break;
        }
    }
    
    OSStatus status = AudioQueueNewOutput(&audioStreamBasicDesc_, audioQueueOutputCallback, (__bridge void*)self, NULL, NULL, 0, &audioQueue_);
    if (status != noErr) {
      NSLog(@"Could not create new output.");
      return NO;
    }

    status = AudioQueueAddPropertyListener(audioQueue_, kAudioQueueProperty_IsRunning, audioQueueIsRunningCallback, (__bridge void*)self);
    if (status != noErr) {
      NSLog(@"Could not add propery listener. (kAudioQueueProperty_IsRunning)");
      return NO;
    }

    for (NSInteger i = 0; i < kNumAQBufs; ++i) {
      status = AudioQueueAllocateBufferWithPacketDescriptions(audioQueue_,
                                                              audioStreamBasicDesc_.mSampleRate * kAudioBufferSeconds / 8,
                                                              _audioCodecContext->sample_rate * kAudioBufferSeconds / (_audioCodecContext->frame_size + 1),
                                                              &audioQueueBuffer_[i]);
      if (status != noErr) {
        NSLog(@"Could not allocate buffer.");
        return NO;
      }
    }
    
    return YES;
}

- (void)removeAudioQueue
{
    [self _stopAudio];
    started_ = NO;

    for (NSInteger i = 0; i < kNumAQBufs; ++i) {
      AudioQueueFreeBuffer(audioQueue_, audioQueueBuffer_[i]);
    }
    
    AudioQueueDispose(audioQueue_, YES);
    
    if (decodeLock_) {
        [decodeLock_ unlock];
        decodeLock_ = nil;
    }
}


- (void)audioQueueOutputCallback:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer
{
    if (state_ == AUDIO_STATE_PLAYING) {
      [self enqueueBuffer:inBuffer];
    }
}

- (void)audioQueueIsRunningCallback
{
    UInt32 isRunning;
    UInt32 size = sizeof(isRunning);
    OSStatus status = AudioQueueGetProperty(audioQueue_, kAudioQueueProperty_IsRunning, &isRunning, &size);

    if (status == noErr && !isRunning && state_ == AUDIO_STATE_PLAYING) {
      state_ = AUDIO_STATE_STOP;

      if (finished_) {
      }
    }
}

- (void)checkAndRestartAudioQueueIfNeeded {
    UInt32 isRunning = 0;
    UInt32 size = sizeof(isRunning);
    OSStatus status = AudioQueueGetProperty(audioQueue_, kAudioQueueProperty_IsRunning, &isRunning, &size);
    
    if (status != noErr) {
        NSLog(@"Error checking Audio Queue status: %d", (int)status);
        [self handleAudioQueueError:status];
    } else if (isRunning == 0) {
        NSLog(@"Audio Queue stopped unexpectedly. Attempting to restart.");
        [self createAudioQueue];
        [self startQueue];
    }
}

- (void)handleAudioQueueError:(OSStatus)error {
    NSLog(@"Audio Queue Error: %d", (int)error);
    [self _stopAudio];
    [self createAudioQueue];
}

- (OSStatus)enqueueBuffer:(AudioQueueBufferRef)buffer
{
    OSStatus status = noErr;
    
    if (buffer) {
        buffer->mAudioDataByteSize = 0;
        buffer->mPacketDescriptionCount = 0;
        
        if (_streamer.audioPacketQueue.count <= 0) {
            _streamer.queueAudioBuffer = buffer;
            return status;
        }

        _streamer.queueAudioBuffer = nil;
        
        if (_streamer.audioPacketQueue.count && buffer->mPacketDescriptionCount < buffer->mPacketDescriptionCapacity) {
            AVPacket *packet = [_streamer readAudioPacket];
            
            if (buffer->mAudioDataBytesCapacity - buffer->mAudioDataByteSize >= packet->size) {
                
                memcpy((uint8_t *)buffer->mAudioData + buffer->mAudioDataByteSize, packet->data, packet->size);
                buffer->mPacketDescriptions[buffer->mPacketDescriptionCount].mStartOffset = buffer->mAudioDataByteSize;
                buffer->mPacketDescriptions[buffer->mPacketDescriptionCount].mDataByteSize = packet->size;
                buffer->mPacketDescriptions[buffer->mPacketDescriptionCount].mVariableFramesInPacket = _audioCodecContext->frame_size;
                
                buffer->mAudioDataByteSize += packet->size;
                buffer->mPacketDescriptionCount++;
                
                
                _streamer.audioPacketQueueSize -= packet->size;
                            
                av_packet_unref(packet);
            }
        }
        
        [decodeLock_ lock];
            status = AudioQueueEnqueueBuffer(audioQueue_, buffer, 0, NULL);
            if (status != noErr) { 
                NSLog(@"Could not enqueue buffer.");
            }
        [decodeLock_ unlock];
    }
    
    return status;
}

- (OSStatus)startQueue
{
    OSStatus status = noErr;

    if (!started_) {
      status = AudioQueueStart(audioQueue_, NULL);
      if (status == noErr) {
        started_ = YES;
      }
      else {
        NSLog(@"Could not start audio queue.");
      }
    }

    return status;
}

@end
