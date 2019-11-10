#import "CordovaHttpPluginChunk.h"
#import "CDVFile.h"
#import "TextResponseSerializer.h"
#import "AFHTTPSessionManager.h"

@interface CordovaHttpPluginChunk()

- (void)setRequestHeaders:(NSDictionary*)headers forManager:(AFHTTPSessionManager*)manager;
- (void)setResults:(NSMutableDictionary*)dictionary withTask:(NSURLSessionTask*)task;

@end


@implementation CordovaHttpPluginChunk {
    AFSecurityPolicy *securityPolicy;
}

- (void)pluginInitialize {
    securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
}

- (void)setRequestHeaders:(NSDictionary*)headers forManager:(AFHTTPSessionManager*)manager {
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [manager.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
}

- (void)setResults:(NSMutableDictionary*)dictionary withTask:(NSURLSessionTask*)task {
    if (task.response != nil) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        [dictionary setObject:[NSNumber numberWithInt:response.statusCode] forKey:@"status"];
        [dictionary setObject:response.allHeaderFields forKey:@"headers"];
    }
}

- (void)enableSSLPinning:(CDVInvokedUrlCommand*)command {
    bool enable = [[command.arguments objectAtIndex:0] boolValue];
    if (enable) {
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    } else {
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)acceptAllCerts:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    bool allow = [[command.arguments objectAtIndex:0] boolValue];
    
    securityPolicy.allowInvalidCertificates = allow;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)validateDomainName:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    bool validate = [[command.arguments objectAtIndex:0] boolValue];
    
    securityPolicy.validatesDomainName = validate;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)post:(CDVInvokedUrlCommand*)command {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.securityPolicy = securityPolicy;
    NSString *url = [command.arguments objectAtIndex:0];
    NSDictionary *parameters = [command.arguments objectAtIndex:1];
    NSDictionary *headers = [command.arguments objectAtIndex:2];
    [self setRequestHeaders: headers forManager: manager];
   
    CordovaHttpPluginChunk* __weak weakSelf = self;
    manager.responseSerializer = [TextResponseSerializer serializer];
    [manager POST:url parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        [dictionary setObject:responseObject forKey:@"data"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } failure:^(NSURLSessionTask *task, NSError *error) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        [dictionary setObject:errResponse forKey:@"error"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)get:(CDVInvokedUrlCommand*)command {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.securityPolicy = securityPolicy;
    NSString *url = [command.arguments objectAtIndex:0];
    NSDictionary *parameters = [command.arguments objectAtIndex:1];
    NSDictionary *headers = [command.arguments objectAtIndex:2];
    [self setRequestHeaders: headers forManager: manager];
   
    CordovaHttpPluginChunk* __weak weakSelf = self;
   
    manager.responseSerializer = [TextResponseSerializer serializer];
    [manager GET:url parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        [dictionary setObject:responseObject forKey:@"data"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } failure:^(NSURLSessionTask *task, NSError *error) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        [dictionary setObject:errResponse forKey:@"error"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getChunked:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    NSString *urlString = [command.arguments objectAtIndex:0];
    NSDictionary *parameters = [command.arguments objectAtIndex:1];
    NSMutableArray *queryItems = [NSMutableArray array];
    for (NSString *key in parameters) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:parameters[key]]];
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    components.queryItems = queryItems;
    NSDictionary *headers = [command.arguments objectAtIndex:2];
    NSURL *url = components.URL;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: self delegateQueue: [NSOperationQueue mainQueue]];
 
    NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithRequest:request];
    [self.commandDelegate runInBackground:^{
        // Some blocking logic...
        [dataTask resume];
    }];
}

- (void)head:(CDVInvokedUrlCommand*)command {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.securityPolicy = securityPolicy;
    NSString *url = [command.arguments objectAtIndex:0];
    NSDictionary *parameters = [command.arguments objectAtIndex:1];
    NSDictionary *headers = [command.arguments objectAtIndex:2];
    [self setRequestHeaders: headers forManager: manager];
    
    CordovaHttpPluginChunk* __weak weakSelf = self;
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager HEAD:url parameters:parameters success:^(NSURLSessionTask *task) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        // no 'body' for HEAD request, omitting 'data'
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } failure:^(NSURLSessionTask *task, NSError *error) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        [dictionary setObject:errResponse forKey:@"error"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)uploadFile:(CDVInvokedUrlCommand*)command {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.securityPolicy = securityPolicy;
    NSString *url = [command.arguments objectAtIndex:0];
    NSDictionary *parameters = [command.arguments objectAtIndex:1];
    NSDictionary *headers = [command.arguments objectAtIndex:2];
    NSString *filePath = [command.arguments objectAtIndex: 3];
    NSString *name = [command.arguments objectAtIndex: 4];
    
    NSURL *fileURL = [NSURL URLWithString: filePath];
    
    [self setRequestHeaders: headers forManager: manager];
    
    CordovaHttpPluginChunk* __weak weakSelf = self;
    manager.responseSerializer = [TextResponseSerializer serializer];
    [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSError *error;
        [formData appendPartWithFileURL:fileURL name:name error:&error];
        if (error) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setObject:[NSNumber numberWithInt:500] forKey:@"status"];
            [dictionary setObject:@"Could not add file to post body." forKey:@"error"];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
    } progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } failure:^(NSURLSessionTask *task, NSError *error) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        [dictionary setObject:errResponse forKey:@"error"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}


- (void)downloadFile:(CDVInvokedUrlCommand*)command {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.securityPolicy = securityPolicy;
    NSString *url = [command.arguments objectAtIndex:0];
    NSDictionary *parameters = [command.arguments objectAtIndex:1];
    NSDictionary *headers = [command.arguments objectAtIndex:2];
    NSString *filePath = [command.arguments objectAtIndex: 3];
   
    [self setRequestHeaders: headers forManager: manager];
    
    if ([filePath hasPrefix:@"file://"]) {
        filePath = [filePath substringFromIndex:7];
    }
    
    CordovaHttpPluginChunk* __weak weakSelf = self;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        /*
         *
         * Licensed to the Apache Software Foundation (ASF) under one
         * or more contributor license agreements.  See the NOTICE file
         * distributed with this work for additional information
         * regarding copyright ownership.  The ASF licenses this file
         * to you under the Apache License, Version 2.0 (the
         * "License"); you may not use this file except in compliance
         * with the License.  You may obtain a copy of the License at
         *
         *   http://www.apache.org/licenses/LICENSE-2.0
         *
         * Unless required by applicable law or agreed to in writing,
         * software distributed under the License is distributed on an
         * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
         * KIND, either express or implied.  See the License for the
         * specific language governing permissions and limitations
         * under the License.
         *
         * Modified by Andrew Stephan for Sync OnSet
         *
        */
        // Download response is okay; begin streaming output to file
        NSString* parentPath = [filePath stringByDeletingLastPathComponent];
        
        // create parent directories if needed
        NSError *error;
        if ([[NSFileManager defaultManager] createDirectoryAtPath:parentPath withIntermediateDirectories:YES attributes:nil error:&error] == NO) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setObject:[NSNumber numberWithInt:500] forKey:@"status"];
            if (error) {
                [dictionary setObject:[NSString stringWithFormat:@"Could not create path to save downloaded file: %@", [error localizedDescription]] forKey:@"error"];
            } else {
                [dictionary setObject:@"Could not create path to save downloaded file" forKey:@"error"];
            }
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        NSData *data = (NSData *)responseObject;
        if (![data writeToFile:filePath atomically:YES]) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setObject:[NSNumber numberWithInt:500] forKey:@"status"];
            [dictionary setObject:@"Could not write the data to the given filePath." forKey:@"error"];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
   
        id filePlugin = [self.commandDelegate getCommandInstance:@"File"];
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        [dictionary setObject:[filePlugin getDirectoryEntry:filePath isDirectory:NO] forKey:@"file"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } failure:^(NSURLSessionTask *task, NSError *error) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [self setResults: dictionary withTask: task];
        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        [dictionary setObject:errResponse forKey:@"error"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
}
 
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSString * str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = @{ @"content": str };
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if(error == nil)
    {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setValue:[NSNumber numberWithBool:YES] forKey:@"end"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
    else {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        [dictionary setObject:[NSNumber numberWithInt:500] forKey:@"status"];
        [dictionary setObject:@"Could not write the data to the given filePath." forKey:@"error"];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dictionary];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

@end