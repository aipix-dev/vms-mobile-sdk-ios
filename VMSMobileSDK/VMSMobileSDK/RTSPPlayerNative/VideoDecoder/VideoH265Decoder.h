#import "VideoDecoderProtocol.h"

#define VIDEO_H265_NAL_TYPE 0x7E

#define VIDEO_H265_VPS 0x20
#define VIDEO_H265_SPS 0x21
#define VIDEO_H265_PPS 0x22

@interface VideoH265Decoder: NSObject <VideoDecoderProtocol>


@end
