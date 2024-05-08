#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoToolbox/VideoToolbox.h"
#include "avformat.h"
#import "avcodec.h"
#import "avio.h"
#import "swscale.h"
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioToolbox.h>

@interface RTSPPlayerFFMPEG : NSObject {
    AVFormatContext     *videoFormatCtx;
    AVCodecContext      *videoCodecCtx;
    AVFrame             *videoFrame;
    AVFrame             *audioFrame;
    AVStream            *videoStream;
    AVStream            *audioStream;
    AVPacket            packet;
    int64_t             packetPTS;
    AVFrame             *picture;
    uint8_t             *viBitmap;
    int                 videoStreamIndex;
    int                 audioStreamIndex;
    struct              SwsContext *img_convert_ctx;
    int                 sourceWidth, sourceHeight;
    int                 outputWidth, outputHeight;
    double              duration;
    double              currentTime;
    int                 frameRate;
    int                 retryCount;
    int                 retryReadCount;
    BOOL                isReleaseResources;
    double              imageTimestamp;
    bool                canPlaySound;
    NSUInteger          _audioBufferSize;
    int16_t             *_audioBuffer;
    BOOL                _inBuffer;
    int                 audioPacketQueueSize;
    NSMutableArray      *audioPacketQueue;
    NSLock              *audioPacketQueueLock;
    BOOL                primed;
    AVPacket            *_packet, _currentPacket;
}

/* Audio codec context ref */
@property (nonatomic, assign) AVCodecContext *_audioCodecContext;

/* Audio stream ref */
@property (nonatomic, assign) AVStream *_audioStream;

/* Audio packet queue */
@property (nonatomic, strong) NSMutableArray *audioPacketQueue;

/* Audio packet queue size*/
@property (nonatomic, assign) int audioPacketQueueSize;

/* Last decoded audio queue buffer ref */
@property (nonatomic, assign) AudioQueueBufferRef queueAudioBuffer;

/* Last decoded picture as UIImage */
@property (nonatomic, readonly) UIImage *currentImage;

/* Size of video frame */
@property (nonatomic, readonly) int sourceWidth, sourceHeight;

/* Output image size. Set to the source size by default. */
@property (nonatomic) int outputWidth, outputHeight;

/* Length of video in seconds */
@property (nonatomic, readonly) double duration;

/* Current time of video in seconds */
@property (nonatomic, readonly) double currentTime;

/* Start date of video SDP packet */
@property (nonatomic, readonly) double sdpStartTime;

/* End date of video SDP packet */
@property (nonatomic, readonly) double sdpEndTime;

/* Current frame rate of video in frames per second */
@property (nonatomic, readonly) int frameRate;

/* Initialize with movie at moviePath. Output dimensions are set to source dimensions.
 Can return initialisation errors*/
- (id)initWithVideo: (NSString *)moviePath
              speed: (double)speed
          withAudio: (BOOL)withAudio
   didFailWithError: (out NSError **)error;

/* Read the next frame from the video stream. Returns false if no frame read (video over).
 Can return playback errors*/
- (id)stepVideoFrame: (BOOL)soundOn
    didFailWithError: (out NSError **)error;

/* Read the next frame from the audio stream. Can return playback errors*/
- (id)stepAudioFrame: (BOOL)soundOn
    didFailWithError: (out NSError **)error;

/* Seek to closest keyframe near specified time */
- (void)seekTime: (double)seconds;

/* Cancel any task of finding stream info or extracting frames. Need to call this method if we need to scroll the timeline before the video is appearing and player be deinited */
- (void)cancel;

- (void)closeAudio;
- (BOOL)canPlayAudio;
- (AVPacket*)readAudioPacket;

@end
