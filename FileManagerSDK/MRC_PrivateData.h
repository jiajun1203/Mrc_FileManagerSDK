//
//  MRC_PrivateData.h
//  FileManagerSDK
//
//  Created by 李沛 on 2020/11/27.
//  Copyright © 2020 Mr.陈. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MRC_PrivateData : NSObject
+ (instancetype)shareManager;
@property (nonatomic ,strong)NSArray *musicArr;
@property (nonatomic ,strong)NSArray *videoArr;
@property (nonatomic ,strong)NSArray *picArr;
@property (nonatomic ,strong)NSArray *textArr;
@property (nonatomic ,strong)NSArray *zipArr;
@property (nonatomic ,strong)NSArray *htmlArr;
@end

NS_ASSUME_NONNULL_END
