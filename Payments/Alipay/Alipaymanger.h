//
//  Alipaymanger.h
//  Pods
//
//  Created by lzc1104 on 2017/9/7.
//
//

#import <Foundation/Foundation.h>

typedef void(^AlipayCallback)(NSDictionary *);

@interface Alipaymanger : NSObject
+ (instancetype) shared;
    
- (void)deliver:(NSString *) urlString
         scheme:(NSString *)scheme
       callback:(AlipayCallback )callback;
    
- (void)processOrderWithPaymentResult:(NSURL *)resultUrl
                      standbyCallback:(AlipayCallback)completionBlock;
@end
