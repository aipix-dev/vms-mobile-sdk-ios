#import "VideoH265Decoder.h"

@interface VideoH265Decoder ()

@property (nonatomic, assign) VTDecompressionSessionRef decompressionSession;
@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDescription;

@property (nonatomic, assign) uint8_t *packetBuffer;
@property (nonatomic, assign) long packetSize;

@property (nonatomic, assign) uint8_t *vps;
@property (nonatomic, assign) long vpsSize;
@property (nonatomic, assign) uint8_t *sps;
@property (nonatomic, assign) long spsSize;
@property (nonatomic, assign) uint8_t *pps;
@property (nonatomic, assign) long ppsSize;

@property (nonatomic, assign) unsigned char h265NalType;

@property (nonatomic, assign) BOOL needCurrentImage;

@end

@implementation VideoH265Decoder

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
    
    if (_vps) {
        free(_vps);
        _vps = NULL;
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
    
    int nalType = (_packetBuffer[4] & VIDEO_H265_NAL_TYPE) >> 1;
    _h265NalType = _packetBuffer[4];
    
    switch (nalType) {
        case 0x20:
            _vpsSize = _packetSize - 4;
            _vps = malloc(_vpsSize);
            memcpy(_vps, _packetBuffer + 4, _vpsSize);
            //            if(_decompressionSession) {
            //                VTDecompressionSessionInvalidate(_decompressionSession);
            //                CFRelease(_decompressionSession);
            //                _decompressionSession = NULL;
            //            }
            //VPS
            break;
        case 0x21:
            _spsSize = _packetSize - 4;
            _sps = malloc(_spsSize);
            memcpy(_sps, _packetBuffer + 4, _spsSize);
            //SPS
            break;
        case 0x22:
            _ppsSize = _packetSize - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, _packetBuffer + 4, _ppsSize);
            //PPS
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

void didDecompressH265(void *decompressionOutputRefCon,
                   void *sourceFrameRefCon,
                   OSStatus status,
                   VTDecodeInfoFlags infoFlags,
                   CVImageBufferRef pixelBuffer,
                   CMTime presentationTimeStamp,
                   CMTime presentationDuration) {
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

- (void)initVideoToolBox {
    if (!_decompressionSession) {
        
        const uint8_t* parameterSetPointers[3] = {_vps, _sps, _pps};
        const size_t parameterSetSizes[3] = {_vpsSize, _spsSize, _ppsSize};
        OSStatus status = CMVideoFormatDescriptionCreateFromHEVCParameterSets(kCFAllocatorDefault,
                                                                              3, //param count
                                                                              parameterSetPointers,
                                                                              parameterSetSizes,
                                                                              4, //nal start code size
                                                                              NULL,
                                                                              &_formatDescription);
        if (status == noErr) {
            CFDictionaryRef attrs = NULL;
            const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
            uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            
            const void *values[] = {
                CFNumberCreate(NULL,
                               kCFNumberSInt32Type,
                               &v)
            };
            
            attrs = CFDictionaryCreate(NULL, 
                                       keys,
                                       values,
                                       1,
                                       NULL,
                                       NULL);
            
            VTDecompressionOutputCallbackRecord callBackRecord;
            callBackRecord.decompressionOutputCallback = didDecompressH265;
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
    
    OSStatus status = CMBlockBufferCreateEmpty(NULL, 
                                               0,
                                               0,
                                               &blockBuffer);

    int lastOffset = -1;
    for (int i = 0; i < _packetSize - 4; i++) {
        // Search for a NALU
        if (_packetBuffer[i] == 0 && _packetBuffer[i+1] == 0 && _packetBuffer[i+2] == 1) {
            // It's the start of a new NALU
            if (lastOffset != -1) {
                // We've seen a start before this so enqueue that NALU
                [self updateBufferForRange: blockBuffer
                                      data: _packetBuffer 
                                    offset: lastOffset
                                    length: i - lastOffset];
            }
            lastOffset = i;
        }
    }
    
    if (lastOffset != -1) {
        // Enqueue the remaining data
        [self updateBufferForRange: blockBuffer
                              data: _packetBuffer
                            offset: lastOffset
                            length: _packetSize - lastOffset];
    }
    
    CMSampleTimingInfo timming;
    timming.decodeTimeStamp = CMTimeMake(1, 29970);
    timming.presentationTimeStamp = CMTimeMake(1, 29970);
    timming.duration = CMTimeMake(1, 29970);
    
    status = CMSampleBufferCreate(kCFAllocatorDefault,
                                  blockBuffer,
                                  true, 
                                  NULL,
                                  NULL, 
                                  _formatDescription,
                                  1,
                                  0,
                                  &timming, 
                                  0,
                                  NULL,
                                  &sampleBuffer);
    if (status != noErr) {
        NSLog(@"CMSampleBufferCreate failed: %d", (int)status);
        CFRelease(blockBuffer);
        return NULL;
    }
    
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_IsDependedOnByOthers, kCFBooleanTrue);
    
    if (![self isNalReferencePicture: _h265NalType]) {
        // P-frame
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_NotSync, kCFBooleanTrue);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DependsOnOthers, kCFBooleanTrue);
    } else {
        // I-frame
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_NotSync, kCFBooleanFalse);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DependsOnOthers, kCFBooleanFalse);
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

- (void)updateBufferForRange: (CMBlockBufferRef)existingBuffer
                        data: (unsigned char *)data
                      offset: (int)offset
                      length: (long)nalLength {
    OSStatus status;
    size_t oldOffset = CMBlockBufferGetDataLength(existingBuffer);
    
    // If we're at index 1 (first NALU in frame), enqueue this buffer to the memory block
    // so it can handle freeing it when the block buffer is destroyed
    if (offset == 1) {
        long dataLength = nalLength - 4;
        
        // Pass the real buffer pointer directly (no offset)
        // This will give it to the block buffer to free when it's released.
        // All further calls to CMBlockBufferAppendMemoryBlock will do so
        // at an offset and will not be asking the buffer to be freed.
        status = CMBlockBufferAppendMemoryBlock(existingBuffer, 
                                                data,
                                                nalLength + 1, // Add 1 for the offset we decremented
                                                kCFAllocatorDefault,
                                                NULL, 
                                                0,
                                                nalLength + 1,
                                                0);
        if (status != noErr) {
            NSLog(@"CMBlockBufferReplaceDataBytes failed: %d", (int)status);
            return;
        }
        
        // Write the length prefix to existing buffer
        const uint8_t lengthBytes[] = {
            (uint8_t)(dataLength >> 24),
            (uint8_t)(dataLength >> 16),
            (uint8_t)(dataLength >> 8),
            (uint8_t)dataLength
        };
        
        status = CMBlockBufferReplaceDataBytes(lengthBytes, 
                                               existingBuffer,
                                               oldOffset, 
                                               4);
        if (status != noErr) {
            NSLog(@"CMBlockBufferReplaceDataBytes failed: %d", (int)status);
            return;
        }
    } else {
        // Append a 4 byte buffer to this block for the length prefix
        status = CMBlockBufferAppendMemoryBlock(existingBuffer, 
                                                NULL,
                                                4,
                                                kCFAllocatorDefault, 
                                                NULL,
                                                0,
                                                4, 
                                                0);
        if (status != noErr) {
            NSLog(@"CMBlockBufferAppendMemoryBlock failed: %d", (int)status);
            return;
        }
        
        // Write the length prefix to the new buffer
        long dataLength = nalLength - 4;
        
        const uint8_t lengthBytes[] = {
            (uint8_t)(dataLength >> 24),
            (uint8_t)(dataLength >> 16),
            (uint8_t)(dataLength >> 8),
            (uint8_t)dataLength
        };
        
        status = CMBlockBufferReplaceDataBytes(lengthBytes, 
                                               existingBuffer,
                                               oldOffset, 
                                               4);
        if (status != noErr) {
            NSLog(@"CMBlockBufferReplaceDataBytes failed: %d", (int)status);
            return;
        }
        
        // Attach the buffer by reference to the block buffer
        status = CMBlockBufferAppendMemoryBlock(existingBuffer, 
                                                &data[offset+4],
                                                dataLength,
                                                kCFAllocatorNull, // Don't deallocate data on free
                                                NULL, 
                                                0,
                                                dataLength,
                                                0);
        if (status != noErr) {
            NSLog(@"CMBlockBufferReplaceDataBytes failed: %d", (int)status);
            return;
        }
    }
}

- (BOOL)isNalReferencePicture: (unsigned char)nalType {
    // HEVC has several types of reference NALU types
    switch (nalType) {
        case 0x20:
        case 0x22:
        case 0x24:
        case 0x26:
        case 0x28:
        case 0x2A:
            return true;
        default:
            return false;
    }
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

- (void)setVPS:(NSMutableData *)vps setSPS:(NSMutableData *)sps setPPS:(NSMutableData *)pps {
}


@end
