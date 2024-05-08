#import <Foundation/Foundation.h>

@interface ParsableBitArray : NSObject

@property (nonatomic, strong) NSData *data;
@property int byteOffset;
@property int bitOffset;
@property int byteLimit;

- (instancetype)init;
- (instancetype)initWithData: (NSData *)data;
- (instancetype)initWithData: (NSData *)data limit: (int)limit;
- (void)resetWithData: (NSData *)data;
- (void)resetWithData: (NSData *)data limit: (int)limit;
- (int)bitsLeft;
- (int)readBits: (int)numBits;

@end
