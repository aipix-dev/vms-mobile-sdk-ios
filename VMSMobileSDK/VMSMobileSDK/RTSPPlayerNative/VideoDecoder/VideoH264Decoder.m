#import "VideoH264Decoder.h"

@interface VideoH264Decoder ()

@property (nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDescription;

@property (nonatomic, assign) uint8_t *packetBuffer;
@property (nonatomic, assign) long packetSize;

@property (nonatomic, assign) uint8_t *sps;
@property (nonatomic, assign) long spsSize;
@property (nonatomic, assign) uint8_t *pps;
@property (nonatomic, assign) long ppsSize;

@property (nonatomic, assign) BOOL needCurrentImage;

@end

@implementation VideoH264Decoder

@synthesize delegate;

- (instancetype)initWithDelegate: (id<VideoDecoderDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.needCurrentImage = NO;
    }
    return self;
}

- (void)dealloc {
    [self clearDecoder];
    
    if (_packetBuffer) {
        _packetBuffer = NULL;
    }
    
    if (_sps) {
        free(_sps);
        _sps = NULL;
    }
    
    if (_pps) {
        free(_pps);
        _pps = NULL;
    }
    
    delegate = NULL;
}

- (void) setVPS:(NSMutableData *)vps setSPS:(NSMutableData *)sps setPPS:(NSMutableData *)pps {
    if (sps != NULL) {
        _sps = (unsigned char *)sps.bytes;
        _spsSize = sps.length;
    }
    if (pps != NULL) {
        _pps = (unsigned char *)pps.bytes;
        _ppsSize = pps.length;
    }
}

- (void)clearDecoder {
    if (_decompressionSession != NULL) {
        VTDecompressionSessionInvalidate(_decompressionSession);
        CFRelease(_decompressionSession);
        _decompressionSession = NULL;
    }
    
    if (_formatDescription != NULL) {
        CFRelease(_formatDescription);
        _formatDescription = NULL;
    }
}

- (void)decoderHasIdrFrame {
    if ([self.delegate respondsToSelector: @selector(decoderHasIdrFrame)]) {
        [self.delegate decoderHasIdrFrame];
    }
}

- (void)decodeFrame: (NSMutableData *)frameData {
    _packetBuffer = (unsigned char *)frameData.bytes;
    _packetSize = frameData.length;
    
    if (_packetBuffer == NULL) {
        return;
    }
    
    CMSampleBufferRef sampleBuffer = NULL;
    
    uint32_t nalSize = (uint32_t)(_packetSize - 4);
    uint32_t *pNalSize = (uint32_t *)_packetBuffer;
    *pNalSize = CFSwapInt32HostToBig(nalSize);
    
    int nalType = _packetBuffer[4] & VIDEO_H264_NAL_TYPE;
    
    switch (nalType) {
        case VIDEO_H264_FRAME:
            [self initVideoToolBox];
            sampleBuffer = [self decodeToSampleBufferRef];
            if (@available(iOS 17.4, *)) {} else {
                [self decoderHasIdrFrame];
            }
            break;
        case VIDEO_H264_SPS:
            _spsSize = _packetSize - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, _packetBuffer + 4, _spsSize);
            break;
        case VIDEO_H264_PPS:
            _ppsSize = _packetSize - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, _packetBuffer + 4, _ppsSize);
            break;
        default:
            [self initVideoToolBox];
            sampleBuffer = [self decodeToSampleBufferRef];
            break;
    }
    
    if (sampleBuffer) {
        if ([self.delegate respondsToSelector: @selector(decoderHasSampleBuffer:)]) {
            [self.delegate decoderHasSampleBuffer: sampleBuffer];
        }
        CFRelease(sampleBuffer);
    }
}

void didDecompressH264(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration) {
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

- (void)initVideoToolBox {
    if (!_decompressionSession) {
        
        const uint8_t* parameterSetPointers[2] = {_sps, _pps};
        const size_t parameterSetSizes[2] = {_spsSize, _ppsSize};
        OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                              2, //param count
                                                                              parameterSetPointers,
                                                                              parameterSetSizes,
                                                                              4, //nal start code size
                                                                              &_formatDescription);
        if (status == noErr) {
            CFDictionaryRef attrs = NULL;
            const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
            uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
            attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
            
            VTDecompressionOutputCallbackRecord callBackRecord;
            callBackRecord.decompressionOutputCallback = didDecompressH264;
            callBackRecord.decompressionOutputRefCon = NULL;
            
            status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                                  _formatDescription,
                                                  NULL, 
                                                  attrs,
                                                  &callBackRecord,
                                                  &_decompressionSession);
            CFRelease(attrs);
        }
    }
}

- (CMSampleBufferRef)decodeToSampleBufferRef {
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    CMSampleBufferRef sampleBuffer = NULL;
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                         (void*)_packetBuffer,
                                                         _packetSize,
                                                         kCFAllocatorNull,
                                                         NULL,
                                                         0,
                                                         _packetSize,
                                                         0,
                                                         &blockBuffer);
    const size_t sampleSizeArray[] = {_packetSize};
    
    CMSampleTimingInfo timming;
    timming.decodeTimeStamp = CMTimeMake(1, 29970);
    timming.presentationTimeStamp = CMTimeMake(1, 29970);
    timming.duration = CMTimeMake(1, 29970);
    
    status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                       blockBuffer,
                                       _formatDescription,
                                       1,
                                       1,
                                       &timming,
                                       1,
                                       sampleSizeArray,
                                       &sampleBuffer);
    CFRelease(blockBuffer);
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    if (CMSampleBufferIsValid(sampleBuffer)) {
        //        NSLog(@"Valid sample: %@", sampleBuffer);
    } else {
        NSLog(@"Invalid sample: %@", sampleBuffer);
    }
    
    if (status == kCMBlockBufferNoErr && sampleBuffer && _needCurrentImage) {
        VTDecodeFrameFlags flags = 0;
        VTDecodeInfoFlags flagOut = 0;
        OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decompressionSession,
                                                                  sampleBuffer,
                                                                  flags,
                                                                  &outputPixelBuffer,
                                                                  &flagOut);
        if (decodeStatus == noErr) {
            [self decodeImage: outputPixelBuffer];
        }
    }
    
    return sampleBuffer;
}

- (void)decodeImage: (CVPixelBufferRef)pixelBuffer {
    if (pixelBuffer == NULL) {
        return;
    }
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];

    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                       createCGImage:ciImage
                       fromRect:CGRectMake(0, 0,
                              CVPixelBufferGetWidth(pixelBuffer),
                              CVPixelBufferGetHeight(pixelBuffer))];

    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    if (uiImage != NULL && [self.delegate respondsToSelector:@selector(decoderHasScreenshot:)]) {
        [self.delegate decoderHasScreenshot: uiImage];
        _needCurrentImage = NO;
    }
    CGImageRelease(videoImage);
    CVPixelBufferRelease(pixelBuffer);
}

- (void)needCurentImage {
    _needCurrentImage = YES;
}

@end
