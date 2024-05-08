#import <Foundation/Foundation.h>
#import "VideoTrack.h"
#import "AudioTrack.h"

#define VIDEO_CODEC_H264 0
#define VIDEO_CODEC_H265 1
#define AUDIO_CODEC_AAC 0
#define AUDIO_CODEC_UNKNOWN -1

@interface SDPInfo : NSObject

@property NSString *session;
@property NSString *sessionName;
@property int sessionTimeout;
@property long time;
@property VideoTrack *videoTrack;
@property AudioTrack *audioTrack;

+ (SDPInfo *)parseSDPInfoFromParams: (NSString *)params;

@end
