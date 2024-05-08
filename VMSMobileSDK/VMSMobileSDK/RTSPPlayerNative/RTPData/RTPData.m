#import <Foundation/Foundation.h>
#import "RTPData.h"
#import "VideoRTPParser.h"
#import "AudioRTPParser.h"
#import "RTPHeader.h"

@implementation RTPData

uint8_t readHead[HEADER_SIZE] = {0};
uint8_t header[RTP_HEADER_SIZE] = {0};

NSDate *startTime;
NSUInteger totalLength = 0;

NSMutableArray *nalUnitBuffer;
NSMutableArray *audioUnitBuffer;
NSMutableArray *timeStampesBuffer;
BOOL videoCanStart = NO;

dispatch_source_t timer;
BOOL isTimerRunning = NO;

- (instancetype)initWithSdpInfo: (SDPInfo *)sdpInfo
                          speed: (double)speed
                       delegate: (id<RTPDataDelegate>)delegate {
    
    self.delegate = delegate;
    self.speed = speed < 0 ? 0.5 : speed;
    
    self.videoParser = [[VideoRtpParser alloc] init];
    self.audioParser = sdpInfo.audioTrack != NULL
    && sdpInfo.audioTrack.audioCodec == AUDIO_CODEC_AAC
    && sdpInfo.audioTrack.mode != NULL
    ? [[AudioRTPParser alloc]initWithAacMode:sdpInfo.audioTrack.mode]
    : NULL;
    
    self.sdpInfo = sdpInfo;
    timeStampesBuffer = [NSMutableArray array];
    
    if (sdpInfo.videoTrack.frameRate != 0) {
        NSUInteger frameRate = sdpInfo.videoTrack.frameRate;
        self.fps = (_speed <= 2) ? (frameRate * _speed) + (frameRate * _speed) * READ_FRAMERATE_CALCULATED_ACCURACY : frameRate + frameRate * READ_FRAMERATE_CALCULATED_ACCURACY;
    } else {
        self.fps = (_speed <= 2) ? (READ_FRAMERATE_DEFAULT * _speed) + (READ_FRAMERATE_DEFAULT * _speed) * READ_FRAMERATE_CALCULATED_ACCURACY : READ_FRAMERATE_DEFAULT + READ_FRAMERATE_DEFAULT * READ_FRAMERATE_CALCULATED_ACCURACY;
    }
    
    startTime = [NSDate now];
    
    [self startRepeatingTimerWithFPS: _fps];
    
    return self;
}

- (void)openStreamWithData: (NSData *)rtpData {
    if (!_readBuffer) {
        self.readBuffer = [[NSMutableData alloc] initWithData:rtpData];
    } else {
        [self.readBuffer appendData: rtpData];
    }
    if (_readBuffer.length > [self getBufferLimitWithData: rtpData]) {
        [self openStream];
    }
}

- (NSUInteger)getBufferLimitWithData: (NSData *)data {
    if (_readBufferLength == 0) {
        
        totalLength += [data length];
        
        if ([[NSDate date] timeIntervalSinceDate: startTime] >= 0.3) {
            NSLog(@"Buffer length: %lu bytes", (unsigned long)totalLength);
            if (totalLength < READ_BUFFER_LENGTH_DEFAULT) {
                return READ_BUFFER_LENGTH_DEFAULT;
            }
            _readBufferLength = totalLength;
            totalLength = 0;
            startTime = [NSDate now];
        }
        return READ_BUFFER_LENGTH_DEFAULT;
    }
    return _readBufferLength;
}

- (void)startRepeatingTimerWithFPS: (double)fps {
    if (isTimerRunning) {
        return;
    }
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    uint64_t interval = NSEC_PER_SEC / fps;
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval, 0);
    dispatch_source_set_event_handler(timer, ^{
        if (timer != NULL) [self sendNalUnit];
    });
    dispatch_resume(timer);
    isTimerRunning = YES;
    NSLog(@"Timer FPS: %f", fps);
}

- (void)stopRepeatingTimer {
    if (timer) {
        dispatch_source_cancel(timer);
        timer = nil;
        isTimerRunning = NO;
    }
}

- (void)openStream {
    @try {
        if (_rtpStream) {
            [_rtpStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            CFRunLoopStop(CFRunLoopGetCurrent());
            [_rtpStream close];
            [_rtpStream setDelegate: NULL];
        }
        _rtpStream = [[NSInputStream alloc] initWithData: _readBuffer];
        
        self.readBuffer = NULL;
        [_rtpStream setDelegate: self];
        [_rtpStream scheduleInRunLoop: [NSRunLoop currentRunLoop]
                              forMode: NSRunLoopCommonModes];
        [_rtpStream open];
        [[NSRunLoop currentRunLoop] run];
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    }
}

- (void)closeStream {
//    @synchronized (self) {
        @try {
            [self stopRepeatingTimer];
            timer = NULL;
            
            if (_rtpStream) {
                [_rtpStream removeFromRunLoop: [NSRunLoop currentRunLoop]
                                      forMode: NSRunLoopCommonModes];
                CFRunLoopStop(CFRunLoopGetCurrent());
                [_rtpStream close];
                [_rtpStream setDelegate: NULL];
            }
            if (_readBuffer) {
                _readBuffer = NULL;
            }
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@", exception);
        }
//    }
}

- (void)dealloc {
    _header = NULL;
    _sdpInfo = NULL;
    _videoParser = NULL;
    _audioParser = NULL;
    _delegate = NULL;
    nalUnitBuffer = NULL;
    audioUnitBuffer = NULL;
    timeStampesBuffer = NULL;
}

- (void)readHeader {
    [self readDataToBuffer: readHead offset: 0 lenght: HEADER_SIZE];
    
    int packetSize = [self getPacketSize: readHead];
    
    if (packetSize > 1500) {
        self.header = NULL;
        self.readBuffer = NULL;
        if([self.delegate respondsToSelector: @selector(rtpPacketIsCorrupt)]) {
            [self.delegate rtpPacketIsCorrupt];
        }
        return;
    }
    
    if ([self readDataToBuffer: header offset: 0 lenght: sizeof(header)] == sizeof(header)) {
        self.header = [RTPHeader parseData: header packetSize: packetSize];
        if (_header == NULL) {
            BOOL foundHeader = [self searchForNextRtpHeader: header];
            if (foundHeader) {
                packetSize = [self getPacketSize: header];
                
                if (packetSize > 1500) {
                    self.header = NULL;
                    self.readBuffer = NULL;
                    if([self.delegate respondsToSelector: @selector(rtpPacketIsCorrupt)]) {
                        [self.delegate rtpPacketIsCorrupt];
                    }
                    return;
                }
                
                if ([self readDataToBuffer: header offset: 0 lenght: sizeof(header)] == sizeof(header)) {
                    self.header = [RTPHeader parseData: header packetSize: packetSize];
                }
            }
        }
    }
}

- (NSInteger) readDataToBuffer: (uint8_t *)buffer
                        offset: (NSInteger)offset
                        lenght: (NSInteger)length {
    NSInteger readBytes;
    NSInteger totalReadBytes = 0;
    uint8_t tempBuffer[12] = {0};
    
    @try {
        do {
            if (offset != 0 && sizeof(tempBuffer) == 0) {
                [_rtpStream read: tempBuffer maxLength: offset];
            }
            readBytes = [_rtpStream read: buffer maxLength: length - totalReadBytes];
            if (readBytes > 0) {
                totalReadBytes += readBytes;
            } else {
                return totalReadBytes;
            }
        } while (readBytes >= 0 && totalReadBytes < length);
    } @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    }
    return totalReadBytes;
}

- (int)getPacketSize:(uint8_t *)header {
    int packetSize = ((header[2] & 0xFF) << 8) | (header[3] & 0xFF);
    return packetSize;
}

- (BOOL)searchForNextRtpHeader: (uint8_t *)header {
    
    if (sizeof(header) < 4) {
        return NO;
    }
    
    int bytesRemaining = 100000; // 100 KB max to check
    BOOL foundFirstByte = NO;
    BOOL foundSecondByte = NO;
    uint8_t oneByte[1] = {0};
    
    // Search for {0x24, 0x00}
    do {
        if (bytesRemaining-- < 0)
            return NO;
        
        // Read 1 byte
        
        [self readDataToBuffer: oneByte offset: 0 lenght: 1];
        
        if (foundFirstByte) {
            // Found 0x24. Checking for 0x00-0x02.
            if (oneByte[0] == 0x00) {
                foundSecondByte = YES;
            } else {
                foundFirstByte = NO;
            }
        }
        
        if (!foundFirstByte && oneByte[0] == 0x24) {
            // Found 0x24
            foundFirstByte = YES;
        }
    } while (!foundSecondByte);
    
    uint8_t headerBytes[4];
    headerBytes[0] = 0x24;
    headerBytes[1] = oneByte[0];
    
    // Read 2 bytes more (packet size)
    [self readDataToBuffer: oneByte offset: 2 lenght: 2];
    
    return YES;
}

- (void)stream: (NSStream *)stream handleEvent: (NSStreamEvent)eventCode {
    uint8_t *data = NULL;
    NSInteger readBytes;
    
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable:
            @try {
                @synchronized (self) {
                    [self readHeader];
                    if (_header == NULL) {
                        return;
                    }
                    
                    if ([self.header payloadSize] > 0) {
                        data = (uint8_t *)malloc(_header.payloadSize);
                    }
                    
                    readBytes = [self readDataToBuffer: data offset: 0 lenght: _header.payloadSize];
                    if (readBytes < _header.payloadSize) {
                        self.readBuffer = [[NSMutableData alloc] initWithBytes: readHead length: HEADER_SIZE];
                        [self.readBuffer appendBytes: header length: RTP_HEADER_SIZE];
                        [self.readBuffer appendBytes: data length: readBytes];
                        [stream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSRunLoopCommonModes];
                        CFRunLoopStop(CFRunLoopGetCurrent());
                        [stream close];
                        [stream setDelegate: NULL];
                    } else {
                        if (_sdpInfo.videoTrack != NULL && _header.payloadType == _sdpInfo.videoTrack.payloadType) {
                            NSMutableData *nalUnit = [_videoParser processRtpPacketAndGetNalUnit: data length:_header.payloadSize];
                            if (nalUnit != NULL) {
                                if (!videoCanStart) {
                                    uint8_t *packetBuffer = (unsigned char *)nalUnit.bytes;
                                    int nalType = packetBuffer[4] & VIDEO_H264_NAL_TYPE;
                                    if (nalType == VIDEO_H264_FRAME) {
                                        videoCanStart = YES;
                                    }
                                }
                                VideoPacket *packet = [[VideoPacket alloc] init];
                                packet.frame = nalUnit;
                                packet.timeStamp = _header.timeStamp;
                                if (nalUnitBuffer == NULL) {
                                    nalUnitBuffer = [NSMutableArray arrayWithObject: packet];
                                } else {
                                    [nalUnitBuffer addObject: packet];
                                }
                                if (_calculatedFps == 0) {
                                    [timeStampesBuffer addObject: @(_header.timeStamp)];
                                }
                            }
                        } else if (_sdpInfo.audioTrack != NULL && _header.payloadType == _sdpInfo.audioTrack.payloadType) {
                            NSMutableData *sample = [_audioParser processRtpPacketAndGetSample: data length: _header.payloadSize];
                            if (sample != NULL && videoCanStart && _calculatedFps != 0) {
                                if (audioUnitBuffer == NULL) {
                                    audioUnitBuffer = [NSMutableArray arrayWithObject: sample];
                                } else {
                                    [audioUnitBuffer addObject: sample];
                                }
                            }
                        }
                    }
                    if (data) free(data);
                }
            } @catch (NSException *exception) {
                //                NSLog(@"Exception %@", exception);
            }
            break;
        case NSStreamEventEndEncountered:
            [_rtpStream removeFromRunLoop: [NSRunLoop currentRunLoop]
                                  forMode: NSRunLoopCommonModes];
            CFRunLoopStop(CFRunLoopGetCurrent());
            [_rtpStream close];
            [_rtpStream setDelegate: NULL];
            break;
        default:
            break;
    }
}

- (void)sendNalUnit {
    @synchronized (self) {
        @try {
            if (nalUnitBuffer != NULL && nalUnitBuffer.count > 0) {
                if ([self.delegate respondsToSelector: @selector(rtpPacketHasVideoData:timestamp:)]) {
                    id firstObject = [nalUnitBuffer objectAtIndex:0];
                    if ([firstObject isKindOfClass: [VideoPacket class]]) {
                        VideoPacket *packet = (VideoPacket *)firstObject;
                        if (packet.frame != NULL && packet.timeStamp != 0) {
                            [self.delegate rtpPacketHasVideoData: packet.frame timestamp: packet.timeStamp];
                        }
                        [nalUnitBuffer removeObjectAtIndex: 0];
                    }
                }
                if (nalUnitBuffer.count > (_fps * _speed) / READ_FRAMES_IN_BUFFER_ACCURACY && _calculatedFps > 0) {
                    for (NSUInteger i = 0; i < nalUnitBuffer.count; i++) {
                        id objectAtIndex = [nalUnitBuffer objectAtIndex: i];
                        if ([objectAtIndex isKindOfClass: [VideoPacket class]]) {
                            VideoPacket *packet = (VideoPacket *)objectAtIndex;
                            if ([self.delegate respondsToSelector: @selector(rtpPacketHasVideoData:timestamp:)] && packet.frame != NULL && packet.timeStamp != 0) {
                                [self.delegate rtpPacketHasVideoData: packet.frame timestamp: packet.timeStamp];
                            }
                        }
                    }
                    if ([self.delegate respondsToSelector: @selector(rtpPacketNeedResetAudio)]) {
                        [self.delegate rtpPacketNeedResetAudio];
                    }
                    [nalUnitBuffer removeAllObjects];
                    [audioUnitBuffer removeAllObjects];
                    [self stopRepeatingTimer];
                    self.fps = (_speed <= 2)
                    ? (READ_FRAMERATE_DEFAULT * _speed) + (READ_FRAMERATE_DEFAULT * _speed) * READ_FRAMERATE_CALCULATED_ACCURACY
                    : READ_FRAMERATE_DEFAULT + READ_FRAMERATE_DEFAULT * READ_FRAMERATE_CALCULATED_ACCURACY;
                    [self startRepeatingTimerWithFPS: _fps];
                    _calculatedFps = 0;
                }
            }
            if (audioUnitBuffer != NULL && audioUnitBuffer.count > 0) {
                if ([self.delegate respondsToSelector: @selector(rtpPacketHasAudioData:)]) {
                    id firstObject = [audioUnitBuffer objectAtIndex: 0];
                    if ([firstObject isKindOfClass: [NSMutableData class]]) {
                        NSMutableData *sample = (NSMutableData *)firstObject;
                        if (sample != 0) {
                            [self.delegate rtpPacketHasAudioData: sample];
                        }
                        [audioUnitBuffer removeObjectAtIndex: 0];
                    }
                }
            }
            if (self.calculatedFps == 0) {
                [self averageFrameDifference];
            }
        } @catch (NSException *exception) {
            //            NSLog(@"Exception %@", exception);
        }
    }
}

- (void)averageFrameDifference {
    if (timeStampesBuffer.count > AVERAGE_TIMESTAMPS_COUNT_FOR_FPS_CALCULATE) {
        long sumOfDifferences = 0;
        for (NSUInteger i = 1; i < [timeStampesBuffer count]; i++) {
            long difference = [timeStampesBuffer[i] longValue] - [timeStampesBuffer[i - 1] longValue];
            sumOfDifferences += labs(difference);
        }
        double averageDifference = (double)sumOfDifferences / ([timeStampesBuffer count] - 1);
        [self calculateFpsByAverage: averageDifference];
        [timeStampesBuffer removeAllObjects];
    }
}

- (void)calculateFpsByAverage: (double)average {
    @synchronized (self) {
        if (average > 0 && _sdpInfo.videoTrack.sampleRate > 0) {
            int fps = _sdpInfo.videoTrack.sampleRate / average;
            if (fps <= 3) {
                return;
            }
            self.calculatedFps = fps + fps * READ_FRAMERATE_CALCULATED_ACCURACY;
            [self stopRepeatingTimer];
            [self startRepeatingTimerWithFPS: _calculatedFps];
        }
    }
}

@end
