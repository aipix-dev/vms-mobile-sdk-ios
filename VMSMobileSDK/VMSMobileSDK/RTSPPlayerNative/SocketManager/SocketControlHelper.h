#import <Foundation/Foundation.h>
#import "SocketControlManager.h"

#define CRLF (@"\r\n")

@interface SocketControlHelper : NSObject

+ (int)getResponseStatusCode: (NSData* )payloadData;
+ (NSMutableDictionary<NSString *, NSString *> *)getResponseHeaders: (NSData* )payloadData;
+ (NSString *)getResponseLocation: (NSData* )payloadData;
+ (NSString *)getStringFromData: (NSData* )payloadData;
+ (NSMutableString *)getMessageForState: (SocketState)state
                                    url: (NSString *)url
                                    seq: (NSInteger)seq
                              sessionID: (NSString *)sessionID
                              authToken: (NSString *)authToken;
+ (NSInteger)getHeaderContentLength: (NSMutableDictionary<NSString *, NSString *> *)headers;
+ (NSMutableDictionary<NSString *, NSString *> *)getDescribeParams: (NSData *)payloadData;
+ (NSString *)getCurrentStepName: (SocketState)state;

@end
