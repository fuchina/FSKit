//
//  FSURLSession.m
//  FBRetainCycleDetector
//
//  Created by Guazi on 2018/2/2.
//

#import "FSURLSession.h"

@implementation FSURLSession

+ (void)sessionGet:(NSString *)urlString{
    if (!([urlString isKindOfClass:[NSString class]] && urlString.length)) {
        return;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:
                                      ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                          if (error) {
#if DEBUG
                                              NSLog(@"%@",error.localizedDescription);
#endif
                                              return;
                                          }
                                          NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

                                          NSLog(@"%@", [NSThread currentThread]);
                                      }];
    [dataTask resume];
}

+ (void)sessionPost:(NSString *)urlString{
    if (!([urlString isKindOfClass:[NSString class]] && urlString.length)) {
        return;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:url];
    requestM.HTTPMethod = @"POST";
    requestM.HTTPBody = [@"username=520&pwd=520&type=JSON" dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:requestM completionHandler:
                                      ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {                                          
                                          NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                      }];
    //发送请求
    [dataTask resume];}

@end
