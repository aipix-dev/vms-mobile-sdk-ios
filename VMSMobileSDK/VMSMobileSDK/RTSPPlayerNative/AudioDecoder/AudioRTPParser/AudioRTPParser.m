#import "AudioRTPParser.h"

@implementation AudioRTPParser

- (instancetype)initWithAacMode: (NSString *)aacMode {
    if (self) {
        NSString *lowerAacMode = [aacMode lowercaseString];
        _aacMode = [lowerAacMode isEqualToString: [@"AAC-lbr" lowercaseString]] 
            ? AUDIO_DECODER_MODE_LBR
            : AUDIO_DECODER_MODE_HBR;
        _headerScratchBits = [[ParsableBitArray alloc] init];
        _headerScratchBytes = [[ParsableByteArray alloc] init];
        _numBitsAuSize = AUDIO_DECODER_NUM_BITS_AU_SIZES[_aacMode];
        _numBitsAuIndex = AUDIO_DECODER_NUM_BITS_AU_INDEX[_aacMode];
    }
    return self;
}

- (void)dealloc {
    if (_headerScratchBits) {
        _headerScratchBits = NULL;
    }
    
    if (_headerScratchBytes) {
        _headerScratchBytes = NULL;
    }
}

- (NSMutableData *)processRtpPacketAndGetSample: (uint8_t *)data length: (int)length {
    int auHeadersCount = 1;
    
    NSMutableData *audioData = [NSMutableData dataWithBytes:data length: length];
    ParsableByteArray *packet = [[ParsableByteArray alloc] initWithData: audioData limit: length];

    int auHeadersLength = [packet readShort];
    int auHeadersLengthBytes = (auHeadersLength + 7) / 8;
    [_headerScratchBytes resetWithLimit: auHeadersLengthBytes];
    uint8_t *toBytes;
    toBytes = malloc(auHeadersLengthBytes);
    [packet readBytes: toBytes offset: 0 length: auHeadersLengthBytes];
    _headerScratchBytes.data = [NSMutableData dataWithBytes: toBytes length: auHeadersLengthBytes];
    
    [_headerScratchBits resetWithData: _headerScratchBytes.data];

    int bitsAvailable = auHeadersLength - (_numBitsAuSize + _numBitsAuIndex);

    if (bitsAvailable >= 0) {
        auHeadersCount += bitsAvailable / (_numBitsAuSize + _numBitsAuIndex);
    }

    int auSize = [_headerScratchBits readBits: _numBitsAuSize];

    free(toBytes);
    toBytes = NULL;
    if (auHeadersCount == 1) {
        NSUInteger auIndex = [_headerScratchBits readBits: _numBitsAuIndex];

        if (auIndex == 0) {
            if ([packet bytesLeft] == auSize) {
                return [self handleSingleAacFrameWithPacket: packet];
            } else {
                return [self handleFragmentationAacFrameWithPacket: packet auSize: auSize];
            }
        }
    } else {
        if ([self handleFragmentationAacFrameWithPacket: packet auSize: auSize]) {
            NSLog(@"completeFrameIndicator 2");
        }
    }
    return [NSMutableData data];
}

- (NSMutableData *)handleSingleAacFrameWithPacket: (ParsableByteArray *)packet {
    int length = [packet bytesLeft];
    uint8_t *toBytes;
    toBytes = malloc(length);
    [packet readBytes: toBytes offset: 0 length: length];
    packet.data = [NSMutableData dataWithBytes: toBytes length: length];
    free(toBytes);
    toBytes = NULL;
    return packet.data;
}

- (NSMutableData *)handleFragmentationAacFrameWithPacket: (ParsableByteArray *)packet auSize: (int)auSize {
    uint8_t *toBytes;
    toBytes = malloc(auSize);
    [packet readBytes: toBytes offset: 0 length: auSize];
    packet.data = [NSMutableData dataWithBytes: toBytes length: auSize];
    free(toBytes);
    toBytes = NULL;
    return packet.data;
}

@end
