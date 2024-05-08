#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol VideoDecoderDelegate <NSObject>

- (void)decoderHasSampleBuffer: (CMSampleBufferRef)sampleBuffer;
- (void)decoderHasIdrFrame;
- (void)decoderHasScreenshot: (UIImage *)screenshot;

@end

@protocol VideoDecoderProtocol <NSObject>

@property (nonatomic, weak) id<VideoDecoderDelegate> delegate;

- (instancetype)initWithDelegate: (id<VideoDecoderDelegate>)delegate;

- (void) setVPS:(NSMutableData *)vps setSPS:(NSMutableData *)sps setPPS:(NSMutableData *)pps;
- (void)decodeFrame: (NSMutableData *)frameData;
- (void)clearDecoder;
- (void)needCurentImage;

@end
