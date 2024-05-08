#import "VideoDecoderProtocol.h"

#define VIDEO_H264_NAL_TYPE 0x1F

#define VIDEO_H264_FRAME 0x05
#define VIDEO_H264_SPS 0x07
#define VIDEO_H264_PPS 0x08

@interface VideoH264Decoder: NSObject <VideoDecoderProtocol>


@end
