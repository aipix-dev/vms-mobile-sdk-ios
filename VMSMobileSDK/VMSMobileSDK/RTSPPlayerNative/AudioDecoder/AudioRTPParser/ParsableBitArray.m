#import "ParsableBitArray.h"

@implementation ParsableBitArray

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [NSData data];
    }
    return self;
}

- (instancetype)initWithData: (NSData *)data {
    return [self initWithData: data limit: (int)data.length];
}

- (instancetype)initWithData: (NSData *)data limit: (int)limit {
    self = [super init];
    if (self) {
        _data = data;
        _byteLimit = limit;
    }
    return self;
}

- (void)resetWithData: (NSData *)data {
    [self resetWithData: data limit: (int)data.length];
}

- (void)resetWithData: (NSData *)data limit: (int)limit {
    _data = data;
    _byteOffset = 0;
    _bitOffset = 0;
    _byteLimit = limit;
}

- (int)bitsLeft {
    return (_byteLimit - _byteOffset) * 8 - _bitOffset;
}

- (int)readBits: (int)numBits {
    if (numBits == 0) {
        return 0;
    }
    int returnValue = 0;
    _bitOffset += numBits;
    while (_bitOffset > 8) {
        _bitOffset -= 8;
        returnValue |= (((uint8_t *)_data.bytes)[_byteOffset++] & 0xFF) << _bitOffset;
    }
    returnValue |= (((uint8_t *)_data.bytes)[_byteOffset] & 0xFF) >> (8 - _bitOffset);
    returnValue &= 0xFFFFFFFF >> (32 - numBits);
    if (_bitOffset == 8) {
        _bitOffset = 0;
        _byteOffset++;
    }
    return returnValue;
}

@end
