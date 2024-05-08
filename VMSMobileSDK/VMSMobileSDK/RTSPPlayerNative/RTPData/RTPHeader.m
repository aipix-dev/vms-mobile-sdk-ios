#import "RTPHeader.h"
#import "RTPData.h"

@implementation RTPHeader

+ (RTPHeader *)parseData: (uint8_t *)header packetSize: (int)packetSize {
    RTPHeader *rtpHeader = [[RTPHeader alloc] init];

    rtpHeader.version = (header[0] & 0xFF) >> 6;
    if (rtpHeader.version != 2) {
        return NULL;
    }

    rtpHeader.padding = (header[0] & 0x20) >> 5;
    rtpHeader.extension = (header[0] & 0x10) >> 4;
    rtpHeader.marker = (header[1] & 0x80) >> 7;
    rtpHeader.payloadType = header[1] & 0x7F;
    rtpHeader.sequenceNumber = (header[3] & 0xFF) + ((header[2] & 0xFF) << 8);
    rtpHeader.timeStamp = (header[7] & 0xFF) + ((header[6] & 0xFF) << 8) + ((header[5] & 0xFF) << 16) + ((long)(header[4] & 0xFF) << 24) & 0xffffffffL;
    rtpHeader.ssrc = (header[11] & 0xFF) + ((header[10] & 0xFF) << 8) + ((header[9] & 0xFF) << 16) + ((long)(header[8] & 0xFF) << 24) & 0xffffffffL;

    rtpHeader.payloadSize = packetSize - RTP_HEADER_SIZE;

    return rtpHeader;
}

@end
