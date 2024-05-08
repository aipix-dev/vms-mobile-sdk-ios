#import "ParsableByteArray.h"

@implementation ParsableByteArray

- (instancetype)init {
    self = [super init];
    if (self) {
        _data = [NSMutableData data];
    }
    return self;
}

- (instancetype)initWithData: (NSMutableData *)data limit: (int)limit {
    self = [super init];
    if (self) {
        _data = data;
        _limit = limit;
    }
    return self;
}

- (void)resetWithLimit: (int)limit {
    [self resetWithData: (_data.length < limit ? [NSMutableData dataWithLength:limit] : _data) limit: limit];
}

- (void)resetWithData: (NSMutableData *)data limit: (int)limit {
    _data = data;
    _limit = limit;
    _position = 0;
}

- (int)bytesLeft {
    return _limit - _position;
}

- (int)getPosition {
    return _position;
}

- (NSMutableData *)getData {
    return _data;
}

- (int)capacity {
    return (int)_data.length;
}

- (void)readBytes: (uint8_t *)buffer offset: (int)offset length: (int)length {
    [_data getBytes: buffer range: NSMakeRange(_position, length)];
    _position += length;
}

- (short)readShort {
    short value = 0;
    [_data getBytes:&value range: NSMakeRange(_position, sizeof(value))];
    _position += sizeof(value);
    return CFSwapInt16BigToHost(value);
}

@end
