//
//  Alipaymanger.m
//  Pods
//
//  Created by lzc1104 on 2017/9/7.
//
//

#import "Alipaymanger.h"
#import "AlipaySDK.framework/Headers/AlipaySDK.h"

@interface Alipaymanger()

@property (nonatomic, copy) AlipayCallback standbyCallback;
    
@end

@implementation Alipaymanger

- (void)deliver:(NSString *) urlString scheme:(NSString *)scheme callback:(AlipayCallback )callback {
    [[Alipaymanger shared] setStandbyCallback:callback];
    [[AlipaySDK defaultService] payOrder:urlString fromScheme:scheme callback:callback];
    
}

- (void)processOrderWithPaymentResult:(NSURL *)resultUrl {
    AlipayCallback callback = [[Alipaymanger shared] standbyCallback];
    [[AlipaySDK defaultService] processOrderWithPaymentResult:resultUrl standbyCallback: callback];
}

    
+ (instancetype) shared {
    static Alipaymanger *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [Alipaymanger new];
    });
    return instance;
}
    
@end
