#import <Foundation/Foundation.h>

#import <Cordova/CDVPlugin.h>

@interface CordovaHttpPluginChunk : CDVPlugin

@property (nonatomic, strong) NSString* callbackId;

- (void)getChunked:(CDVInvokedUrlCommand*)command;

@end