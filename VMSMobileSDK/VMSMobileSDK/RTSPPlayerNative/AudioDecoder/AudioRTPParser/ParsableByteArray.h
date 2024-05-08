#import <Foundation/Foundation.h>

@interface ParsableByteArray : NSObject

@property (nonatomic, strong) NSMutableData *data;
@property int position;
@property int limit;

- (instancetype)init;
- (instancetype)initWithData: (NSMutableData *)data limit: (int)limit;
- (void)resetWithLimit: (int)limit;
- (void)resetWithData: (NSMutableData *)data limit: (int)limit;
- (int)bytesLeft;
- (int)limit;
- (int)getPosition;
- (NSMutableData *)getData;
- (int)capacity;
- (void)readBytes: (uint8_t *)buffer offset: (int)offset length: (int)length;
- (short)readShort;

@end
