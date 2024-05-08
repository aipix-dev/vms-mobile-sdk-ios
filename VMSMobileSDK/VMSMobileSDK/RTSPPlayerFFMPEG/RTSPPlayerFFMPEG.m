#import <UIKit/UIKit.h>

#import "RTSPPlayerFFMPEG.h"
#import "Utilities.h"
#import "imgutils.h"
#import "packet.h"
#import "error.h"
#import "AudioStreamer.h"

#ifndef AVCODEC_MAX_AUDIO_FRAME_SIZE
# define AVCODEC_MAX_AUDIO_FRAME_SIZE 192000 // 1 second of 48khz 32bit audio
#endif

@interface RTSPPlayerFFMPEG ()
@property (nonatomic, retain) AudioStreamer *audioController;
@end


@interface RTSPPlayerFFMPEG (private)
- (void)convertFrameToRGB;

- (UIImage *)imageFromAVPicture: (AVFrame)pict
                          width: (int)width
                         height: (int)height;

- (void)savePicture: (AVFrame)pFrame
              width: (int)width
             height: (int)height
              index: (int)iFrame;

- (void)setupScaler;

@end

@implementation RTSPPlayerFFMPEG

@synthesize audioController = _audioController;
@synthesize audioPacketQueue, audioPacketQueueSize;
@synthesize _audioStream, _audioCodecContext;
@synthesize queueAudioBuffer;

@synthesize outputWidth, outputHeight;

dispatch_block_t findStreamInfoBlock;
dispatch_semaphore_t findStreamInfoSemaphore;

dispatch_block_t stepVideoFrameBlock;
dispatch_semaphore_t stepVideoFrameSemaphore;

// Identifier for initialisation errors
NSString *const FFMPEGInitError = @"FFMPEGInitError";
// Identifier for playback timeout error
NSString *const FFMPEGInitTimeout = @"FFMPEGInitTimeout";
// Identifier for playback errors
NSString *const FFMPEGPlaybackError = @"FFMPEGPlaybackError";
// Identifier for playback performance errors
NSString *const FFMPEGPlaybackPerformanceError = @"FFMPEGPlaybackPerformanceError";

- (void)setOutputWidth:(int)newValue
{
    if (outputWidth != newValue) {
        outputWidth = newValue;
        [self setupScaler];
    }
}

- (void)setOutputHeight:(int)newValue
{
    if (outputHeight != newValue) {
        outputHeight = newValue;
        [self setupScaler];
    }
}

- (UIImage *)currentImage
{
    if (!videoFrame->data[0]) return nil;
    [self convertFrameToRGB];
    return [self imageFromAVPicture: *(picture)
                              width: outputWidth
                             height: outputHeight];
}

- (double)duration
{
    return (double)videoFormatCtx->duration / AV_TIME_BASE;
}

- (double)currentTime
{
    AVRational timeBase = videoFormatCtx->streams[videoStreamIndex]->time_base;
    return packetPTS * (double)timeBase.num / timeBase.den;
}

- (double)sdpStartTime
{
    // We need to subtract 2208988800 to get the timeInterval in the Unix date format
    return videoFormatCtx->sdp_start_time - 2208988800;
}

- (double)sdpEndTime
{
    // We need to subtract 2208988800 to get the timeInterval in the Unix date format
    return videoFormatCtx->sdp_end_time - 2208988800;
}

- (int)frameRate
{
    if(videoStream->avg_frame_rate.den && videoStream->avg_frame_rate.num) {
        return av_q2d(videoStream->avg_frame_rate);
    }
    return 30;
    
}

- (int)sourceWidth
{
    return videoCodecCtx->width;
}

- (int)sourceHeight
{
    return videoCodecCtx->height;
}

- (BOOL)canPlayAudio {
    return canPlaySound;
}

- (id)initWithVideo:(NSString *)moviePath speed:(double)speed withAudio:(BOOL)withAudio didFailWithError:(out NSError **)error;
{
    if (!(self=[super init])) {
        *error = [self getError: @"FFMPEG init error"
                         domain: FFMPEGInitError
                            url: moviePath];
        return nil;
    };
    // Register all formats and codecs
    avformat_network_init();
    
    videoFormatCtx = avformat_alloc_context();
    
    isReleaseResources = NO;
    const AVCodec *pVideoCodec, *pAudioCodec;
    
    // Set the RTSP Options
    AVDictionary *opts = 0;
    
    av_dict_set(&opts, "flush_packets", "1", 0);
    av_dict_set(&opts, "fflags", "nobuffer", 0);
    av_dict_set(&opts, "flags", "low_delay", 0);
    av_dict_set(&opts, "rtsp_transport", "tcp", 0);
    
    // Init player with url and options
    if (avformat_open_input(&videoFormatCtx, [moviePath UTF8String], NULL, &opts) != 0 ) {
        *error = [self getError: @"Couldn't open URL"
                         domain: FFMPEGInitError
                            url: moviePath];
        return nil;
    }
    
    // Get log of stream format
    //    if (DEBUG) av_dump_format(videoFormatCtx, 0, [moviePath UTF8String], 0);
    
    // Needed to get the timeout, otherwise we can get a freeze.
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    //    findStreamInfoSemaphore = dispatch_semaphore_create(0);
    
    __block NSError *findStreamError;
    
    // We get info about the stream in asynchronous block, otherwise we can get a freeze.
    findStreamInfoBlock = dispatch_block_create(0, ^{
        int ret = avformat_find_stream_info(self->videoFormatCtx, NULL);
        if (ret < 0) {
            findStreamError = [self getError: @"Couldn't find stream information"
                                      domain: FFMPEGInitError
                                         url: moviePath];
        }
        dispatch_semaphore_signal(sema);
    });
    
    // Run asynchronous block.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), findStreamInfoBlock);
    
    findStreamInfoSemaphore = sema;
    
    // Waits 10 seconds for the semaphore signal, else return error
    if (dispatch_semaphore_wait(findStreamInfoSemaphore, dispatch_time(DISPATCH_TIME_NOW, 10.0 / speed * NSEC_PER_SEC))) {
        *error = [self getError: @"Find stream information timeout"
                         domain: FFMPEGInitTimeout
                            url: moviePath];
        if (findStreamInfoBlock) {
            dispatch_cancel(findStreamInfoBlock);
            dispatch_block_cancel(findStreamInfoBlock);
        }
        findStreamInfoSemaphore = nil;
        findStreamInfoBlock = nil;
        return nil;
    } else if (findStreamError) {
        *error = findStreamError;
        return nil;
    }
    
    // Find video stream
    if ((videoStreamIndex = av_find_best_stream(videoFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &pVideoCodec, 0)) < 0) {
        *error = [self getError: @"Couldn't find video stream"
                         domain: FFMPEGInitError
                            url: moviePath];
        return nil;
    }
    
    // Find the decoder for the video stream
    pVideoCodec = avcodec_find_decoder(videoFormatCtx->streams[videoStreamIndex]->codecpar->codec_id);
    
    if (pVideoCodec == NULL) {
        *error = [self getError: @"Unsupported codec"
                         domain: FFMPEGInitError
                            url: moviePath];
        return nil;
    }
    
    // Init codec for the video stream
    videoCodecCtx = avcodec_alloc_context3(pVideoCodec);
    
    if (videoCodecCtx == NULL) {
        *error = [self getError: @"Cannot be played"
                         domain: FFMPEGInitError
                            url: moviePath];
        return nil;
    }
    
    // Get additional parameters for correct playback
    avcodec_parameters_to_context(videoCodecCtx, videoFormatCtx->streams[videoStreamIndex]->codecpar);
    
    // Open codec
    if (avcodec_open2(videoCodecCtx, pVideoCodec, NULL) < 0) {
        *error = [self getError: @"Cannot open video decoder"
                         domain: FFMPEGInitError
                            url: moviePath];
        return nil;
    }
    
    videoStream = videoFormatCtx->streams[videoStreamIndex];
    
    // Audio stream
    if ((audioStreamIndex = av_find_best_stream(videoFormatCtx, AVMEDIA_TYPE_AUDIO, -1, -1, &pAudioCodec, 0)) < 0) {
        audioStreamIndex = -1;
        // If need to disable soundOn button, we can handle error
        // *error = [self getError:@"Couldn't find audio stream" domain:FFMPEGInitError];
    } else {
        _audioCodecContext = avcodec_alloc_context3(NULL);
        avcodec_parameters_to_context(_audioCodecContext, videoFormatCtx->streams[audioStreamIndex]->codecpar);
        
        // Find the decoder for the audio stream
        pAudioCodec = avcodec_find_decoder(_audioCodecContext->codec_id);
        if(pAudioCodec == NULL) {
            av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        }
        
        // Open audio codec
        if(avcodec_open2(_audioCodecContext, pAudioCodec, NULL) < 0) {
            av_log(NULL, AV_LOG_ERROR, "Cannot open audio decoder\n");
        }
        
        canPlaySound = _audioCodecContext->codec_id == AV_CODEC_ID_AAC;
        if (canPlaySound) {
            NSLog(@"set up audiodecoder");
            [self setupAudioDecoderWithCodec];
        }
    }
    
    //    // Allocate video packet
    //    packet = *(AVPacket *)av_malloc(sizeof(AVPacket));
    //
    // Allocate video frame
    videoFrame = av_frame_alloc();
    
    outputWidth = videoCodecCtx->width;
    self.outputHeight = videoCodecCtx->height;
    
    return self;
}

- (void)setupScaler
{
    // Release old picture and scaler
    av_frame_unref(picture);
    av_frame_free(&picture);
    sws_freeContext(img_convert_ctx);
    
    // Allocate RGB picture
    picture = av_frame_alloc();
    
    viBitmap = (uint8_t*)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_RGB24,
                                                            videoCodecCtx->width,
                                                            videoCodecCtx->height, 1));
    picture->width = videoCodecCtx->width;
    picture->height = videoCodecCtx->height;
    picture->format = AV_PIX_FMT_RGB24;
    
    av_image_fill_arrays(picture->data,
                         picture->linesize,
                         viBitmap, AV_PIX_FMT_RGB24,
                         picture->width,
                         picture->height,
                         1);
    
    // Setup scaler
    static int sws_flags = SWS_FAST_BILINEAR;
    img_convert_ctx = sws_getContext(videoCodecCtx->width,
                                     videoCodecCtx->height,
                                     videoCodecCtx->pix_fmt,
                                     outputWidth,
                                     outputHeight,
                                     AV_PIX_FMT_RGB24,
                                     sws_flags,
                                     NULL, NULL, NULL);
}

- (void)seekTime:(double)seconds
{
    AVRational timeBase = videoFormatCtx->streams[videoStreamIndex]->time_base;
    int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
    avformat_seek_file(videoFormatCtx,
                       videoStreamIndex,
                       targetFrame,
                       targetFrame,
                       targetFrame,
                       AVSEEK_FLAG_FRAME);
    avcodec_flush_buffers(videoCodecCtx);
}

- (NSError *)getError:(NSString *)error domain:(NSString *)domain url:(NSString *)url
{
    return  [NSError errorWithDomain: domain
                                code: -1
                            userInfo: @{NSLocalizedDescriptionKey: error,
                                        NSLocalizedFailureReasonErrorKey: url}];
}

- (void)cancel {
    // Cancel any work for finding stream info and frames extracting
    if (findStreamInfoSemaphore) dispatch_semaphore_signal(findStreamInfoSemaphore);
    if (findStreamInfoBlock) {
        dispatch_block_cancel(findStreamInfoBlock);
        dispatch_cancel(findStreamInfoBlock);
    }
    findStreamInfoSemaphore = nil;
    findStreamInfoBlock = nil;
    if (stepVideoFrameSemaphore) dispatch_semaphore_signal(stepVideoFrameSemaphore);
    if (stepVideoFrameBlock) {
        dispatch_block_cancel(stepVideoFrameBlock);
        dispatch_cancel(stepVideoFrameBlock);
    }
    stepVideoFrameSemaphore = nil;
    stepVideoFrameBlock = nil;
}

- (void)dealloc
{
    // Free scaler
    if (img_convert_ctx != NULL) {
        sws_freeContext(img_convert_ctx);
        img_convert_ctx = NULL;
        
        av_frame_unref(picture);
        if (&picture) av_freep(&picture);
    }
    
    if (videoFrame != NULL) {
        av_frame_unref(videoFrame);
        if (videoFrame) av_freep(videoFrame);
        videoFrame = NULL;
    }
    
    if (videoCodecCtx) {
        // Free codec context
        avcodec_free_context(&videoCodecCtx);
        
        // Close the codec
        avcodec_close(videoCodecCtx);
    }
    
    // Free RGB picture and frame
   
    if (audioStreamIndex > -1) {
        avcodec_free_context(&_audioCodecContext);
        avcodec_close(_audioCodecContext);
    }
    
    // Close the video file
    if (videoFormatCtx) {
        avformat_close_input(&videoFormatCtx);
        avformat_free_context(videoFormatCtx);
        videoFormatCtx = NULL;
    }
    
    // Free the packet that was allocated by av_read_frame
    
    if (&packet != NULL) {
        av_packet_unref(&packet);
        if (&packet) av_freep(&packet);
    }
    
    if (viBitmap != NULL) {
        if (&viBitmap) av_freep(&viBitmap);
    }
    
    // Free the YUV frame
    
    avformat_network_deinit();
}

- (id)stepVideoFrame: (BOOL)soundOn didFailWithError: (out NSError **)error;
{
    // Needed to get the timeout, otherwise we can get a freeze.
    stepVideoFrameSemaphore = dispatch_semaphore_create(0);
    
    __block NSError *stepVideoFrameError;
    __block NSError *stepVideoFramePerformanceError;
    
    // We get frame in asynchronous block, otherwise we can get a freeze.
    stepVideoFrameBlock = dispatch_block_create(0, ^{
        @synchronized(self) {
            
            int frameFinished = 0;
            
            while (!frameFinished) {
                
                int result = av_read_frame(self->videoFormatCtx, &(self->packet));
                
                if (result < 0) {
                    if (self->retryReadCount > 50) {
                        stepVideoFramePerformanceError = [self getError: @"Need to break performance error"
                                                      domain: FFMPEGPlaybackPerformanceError
                                                         url: @""];
                    }
                    av_packet_unref(&self->packet);
                    self->retryReadCount += 1;
                    break;
                } else if (result >= 0) {
                    
                    // Is this a packet from the video stream?
                    if (self->packet.stream_index == self->videoStreamIndex) {
                        
                        avcodec_send_packet(self->videoCodecCtx, &self->packet);
                        
                        
                        //Store PTS for calculate current playback time
                        self->packetPTS = self->packet.pts;
                        
                        //Release side data
                        av_packet_free_side_data(&(self->packet));
                        
                        frameFinished = avcodec_receive_frame(self->videoCodecCtx, self->videoFrame);
                        
                        if (frameFinished < 0) {
                            if (frameFinished == AVERROR(EAGAIN)) {
                                av_packet_unref(&self->packet);
                                self->retryCount += 1;
                            }
                            // We can change retry count for less or more attempts
                            if (self->retryCount > 200) {
                                av_packet_unref(&self->packet);
                                stepVideoFrameError = [self getError: @"Need to retry play URL"
                                                              domain: FFMPEGPlaybackError
                                                                 url: @""];
                                break;
                            }
                            if (frameFinished != AVERROR(EAGAIN)) {
                                av_packet_unref(&self->packet);
                                stepVideoFrameError = [self getError: @"Video stream is corrupt"
                                                              domain: FFMPEGInitError
                                                                 url: @""];
                                break;
                            }
                        }
                        if (frameFinished == 0) break;
                        
                    }
                    
                    if (self->packet.stream_index == self->audioStreamIndex) {
                        if (soundOn && self->audioStream > 0) {
                            [self stepAudioFrame: soundOn
                                didFailWithError: &stepVideoFrameError];
                        } else {
                            [self closeAudio];
                        }
                    }
                }
            }
        }
        av_packet_unref(&self->packet);
        if (stepVideoFrameSemaphore) dispatch_semaphore_signal(stepVideoFrameSemaphore);
    });
    
    // Run asynchronous block.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), stepVideoFrameBlock);
    
    // Waits 2 seconds for the semaphore signal, else return error.
    if (dispatch_semaphore_wait(stepVideoFrameSemaphore, dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC))) {
        //        av_packet_unref(&self->packet);
        *error = [self getError: @"Need to break take an empty frame"
                         domain: FFMPEGInitError
                            url: @""];
        return nil;
    } else if (stepVideoFrameError) {
        *error = stepVideoFrameError;
        return nil;
    } else if (stepVideoFramePerformanceError) {
        *error = stepVideoFramePerformanceError;
        return nil;
    }
    return self;
}

- (id)stepAudioFrame: (BOOL)soundOn didFailWithError: (out NSError **)error;
{
    if (self->_audioCodecContext) {
        
        avcodec_send_packet(self->_audioCodecContext, &self->packet);
        
        int ret = avcodec_receive_frame(self->_audioCodecContext, self->audioFrame);
        
        if (ret < 0) {
            if (ret == AVERROR(EAGAIN)) self->retryCount += 1;
            // We can change retry count for less or more attempts
            if (self->retryCount > 200) {
                *error = [self getError: @"Need to retry play URL"
                                 domain: FFMPEGPlaybackError
                                    url: @""];
            }
            if (ret != AVERROR(EAGAIN)) {
                *error = [self getError: @"Audio stream is corrupt"
                                 domain: FFMPEGInitError
                                    url: @""];
            }
        }
        
        [self->audioPacketQueueLock lock];
        
        self->audioPacketQueueSize += self->packet.size;
        
        [self->audioPacketQueue addObject:[NSMutableData dataWithBytes:&self->packet length:sizeof(packet)]];
        
        [self->audioPacketQueueLock unlock];
        
        if (self->queueAudioBuffer) {
            [self->_audioController enqueueBuffer:self->queueAudioBuffer];
        } else {
            NSLog(@"closeAudio called");
            [self closeAudio];
        }
        
        if (!self->primed) {
            self->primed = YES;
            [self->_audioController _startAudio];
        }
    }
    return self;
}

- (void)setupAudioDecoderWithCodec {
    if (audioStream >= 0) {
        
        _audioBufferSize = 192000;
        _audioBuffer = av_malloc(_audioBufferSize);
        _inBuffer = NO;
        audioFrame = av_frame_alloc();
        
        audioStream = videoFormatCtx->streams[audioStreamIndex];
        if (audioPacketQueue) {
            audioPacketQueue = nil;
        }
        audioPacketQueue = [[NSMutableArray alloc] init];
        
        if (audioPacketQueueLock) {
            audioPacketQueueLock = nil;
        }
        audioPacketQueueLock = [[NSLock alloc] init];
        
        if (_audioController) {
            [_audioController _stopAudio];
            _audioController = nil;
        }
        _audioController = [[AudioStreamer alloc] initWithStreamer:self];
    } else {
        videoFormatCtx->streams[audioStreamIndex]->discard = AVDISCARD_ALL;
        audioStreamIndex = -1;
    }
}

- (AVPacket*)readAudioPacket
{
    if (_currentPacket.size > 0 || _inBuffer) return &_currentPacket;
    
    NSMutableData *packetData = [audioPacketQueue objectAtIndex:0];
    _packet = [packetData mutableBytes];
    
    if (_packet) {
        if (_packet->dts != AV_NOPTS_VALUE) {
            _packet->dts += av_rescale_q(0, AV_TIME_BASE_Q, audioStream->time_base);
        }
        
        if (_packet->pts != AV_NOPTS_VALUE) {
            _packet->pts += av_rescale_q(0, AV_TIME_BASE_Q, audioStream->time_base);
        }
        
        [audioPacketQueueLock lock];
        audioPacketQueueSize -= _packet->size;
        if ([audioPacketQueue count] > 0) {
            [audioPacketQueue removeObjectAtIndex:0];
        }
        [audioPacketQueueLock unlock];
        
        _currentPacket = *(_packet);
    }
    
    return &_currentPacket;
}


- (void)convertFrameToRGB
{
    if (img_convert_ctx != NULL) {
        sws_scale(img_convert_ctx,
                  (const uint8_t *const *)videoFrame->data,
                  videoFrame->linesize,
                  0,
                  videoCodecCtx->height,
                  picture->data,
                  picture->linesize);
    }
}

- (UIImage *)imageFromAVPicture: (AVFrame)pict width:(int)width height:(int)height
{
    @try {
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreate(kCFAllocatorDefault, pict.data[0], pict.linesize[0] * height);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        
        NSMutableData *providerData = CGDataProviderGetInfo(provider);
        if ([providerData bytes] == NULL) {
            NSLog(@"Convert buffer not readable.");
            return NULL;
        }

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGImageRef cgImage = CGImageCreate(width,
                                           height,
                                           8,
                                           24,
                                           pict.linesize[0],
                                           colorSpace,
                                           bitmapInfo,
                                           provider,
                                           NULL,
                                           NO,
                                           kCGRenderingIntentDefault);
        
        UIImage *image = [UIImage imageWithCGImage: cgImage];
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(cgImage);
        CGDataProviderRelease(provider);
        CFRelease(data);
        return image;
    } @catch (NSException *exception) {
        NSLog(@"Convert buffer not readable. %@", exception);
    }
}

- (void)savePPMPicture: (AVFrame)pict width: (int)width height: (int)height index: (int)iFrame
{
    FILE *pFile;
    NSString *fileName;
    int y;
    
    fileName = [Utilities documentsPath: [NSString stringWithFormat: @"image%04d.ppm", iFrame]];
    // Open file
    NSLog(@"write image file: %@", fileName);
    pFile = fopen([fileName cStringUsingEncoding: NSASCIIStringEncoding], "wb");
    
    if (pFile == NULL) {
        return;
    }
    
    // Write header
    fprintf(pFile, "P6\n%d %d\n255\n", width, height);
    
    // Write pixel data
    for (y = 0; y < height; y++) {
        fwrite(pict.data[0] + y * pict.linesize[0], 1, width * 3, pFile);
    }
    
    // Close file
    fclose(pFile);
}

- (void)closeAudio
{
    [_audioController _stopAudio];
    primed = NO;
    
}

@end
