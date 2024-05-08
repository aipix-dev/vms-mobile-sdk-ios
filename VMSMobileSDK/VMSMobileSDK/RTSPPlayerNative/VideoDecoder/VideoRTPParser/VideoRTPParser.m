#import "VideoRTPParser.h"

@implementation VideoRtpParser

- (id)init {
    self = [super init];
    if (self) {
        dataBuffer = [[NSMutableArray alloc] init];
        for (int i = 0; i < 1024; i++) {
            [dataBuffer addObject: [NSMutableData data]];
        }
        nalUnit = NULL;
        nalEndFlag = NO;
        bufferLength = 0;
        packetNum = 0;
    }
    return self;
}

- (void)dealloc {
    if (dataBuffer) dataBuffer = NULL;
    if (nalUnit) nalUnit = NULL;
}

- (NSData *)processRtpPacketAndGetNalUnit: (uint8_t *)data length: (int)length {
    if (data == NULL || length == 0) {
        return NULL;
    }
    nalEndFlag = NO;
    
    int tmpLen;
    int nalType = data[0] & NAL_UNIT_TYPE;
    int packFlag = data[1] & NAL_UNIT_PACK_FLAG;
        
    switch (nalType) {
        case NAL_UNIT_TYPE_STAP_A:
            break;
        case NAL_UNIT_TYPE_STAP_B:
            break;
        case NAL_UNIT_TYPE_MTAP16:
            break;
        case NAL_UNIT_TYPE_MTAP24:
            break;
        case NAL_UNIT_TYPE_FU_B:
            break;
        case NAL_UNIT_TYPE_FU_A: {
            switch (packFlag) {
                case NAL_UNIT_START_PACKET: {
                    nalEndFlag = NO;
                    packetNum = 1;
                    bufferLength = length - 1;
                    uint8_t value = (uint8_t)((data[0] & 0xE0) | (data[1] & 0x1F));
                    [dataBuffer[1] setData: [NSMutableData dataWithBytes: &value length: 1]];
                    [dataBuffer[1] appendBytes: data + 2 length: length - 2];
                }
                    break;
                case NAL_UNIT_MIDDLE_PACKET: {
                    nalEndFlag = NO;
                    packetNum++;
                    bufferLength += length - 2;
                    dataBuffer[packetNum] = [NSMutableData dataWithBytes: data + 2 length: length - 2];
                }
                    break;
                case NAL_UNIT_END_PACKET: {
                    nalEndFlag = YES;
                    nalUnit = [NSMutableData dataWithData: [self startCodeData]];
                    tmpLen = 4;
                    @try {
                        if (dataBuffer != NULL && dataBuffer.count > 0 && [dataBuffer[1] length] != 0) {
                            [nalUnit appendData: dataBuffer[1]];
                            tmpLen += [dataBuffer[1] length];
                            for (int i = 2; i < packetNum + 1; ++i) {
                                [nalUnit appendData: dataBuffer[i]];
                                tmpLen += [dataBuffer[i] length];
                            }
                        }
                        [nalUnit appendBytes: data + 2 length: length - 2];
                    } @catch (NSException *exception) {
                        NSLog(@"Exception: %@", exception);
                    }
                }
                break;
            }
        }
        break;
        default:
            nalUnit = [NSMutableData dataWithData: [self startCodeData]];
            [nalUnit appendBytes: data length: length];
            nalEndFlag = YES;
            break;
    }
    if (nalEndFlag == YES) {
        return nalUnit;
    } else {
        return nil;
    }
}

- (NSData *)startCodeData {
    unsigned char startCode[] = {0x00,0x00,0x00,0x01};
    return [NSData dataWithBytes: startCode length: 4];
}

@end
