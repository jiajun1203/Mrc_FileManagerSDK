//
//  MRC_FileManager.m
//  FileManagerSDK
//
//  Created by 李沛 on 2020/11/27.
//  Copyright © 2020 Mr.陈. All rights reserved.
//

#import "MRC_FileManager.h"
@interface MRC_FileManager()
@property (nonatomic, strong) NSMutableArray * optArray;    //操作文件总数
@property (nonatomic, strong) NSMutableArray * fshArray;    //完成文件总数
@property (nonatomic, strong) NSMutableArray * failArray;    //完成文件总数
@end

@implementation MRC_FileManager
static MRC_FileManager *mrc_file_manager = nil;
+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mrc_file_manager = [[self alloc] init];
    });
    return mrc_file_manager;
}
- (NSInteger)finishCount{
    return self.fshArray.count;
}
- (NSInteger)taskCount{
    NSInteger count = self.optArray.count - self.fshArray.count - self.failArray.count;
    if (count < 0) {
        count = 0;
    }
    return count;
}
- (NSInteger)allTaskCount{
    return self.optArray.count;
}
- (BOOL)fileExistsAtPath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    
    if (isDirExist) {
        return isDirExist;
    }
    
    isDir = YES;
    isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    
    return isDirExist;
}
- (BOOL)fileExistsAtItem:(MRC_LocalFileItem *)item{
    return [self fileExistsAtPath:item.path];
}
- (void)clearData{
    if (self.failArray.count + self.fshArray.count == self.optArray.count) {
        [self.failArray removeAllObjects];
        [self.fshArray removeAllObjects];
        [self.optArray removeAllObjects];
    }
}
- (NSError *)getErrorWithDesc:(NSString *)errStr code:(int)code{
    NSString *domain = @"MRC_FILE_ERROR";
    NSString *desc = errStr;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
    NSError *error = [NSError errorWithDomain:domain code:code userInfo:userInfo];
    return error;
}
//创建文件夹 path包涵文件夹名
- (BOOL)mkDirWithPath:(NSString *)path success:(void (^)(BOOL success ,NSString *path))block failed:(void (^)(NSError *error))failedblock{
    MRC_LocalFileItem *item = [[MRC_LocalFileItem alloc]initWithPath:path];
    if (item.isDir) {
       return [item mkDirWithName:item.path success:block failed:failedblock];
    }else{
        failedblock([self getErrorWithDesc:@"路径非文件夹,请勿带后缀" code:-100]);
        return NO;
    }
}

//创建文件  path包涵文件名
- (BOOL)mkFileWithPath:(NSString *)path success:(void (^)(BOOL success ,NSString *path))block failed:(void (^)(NSError *error))failedblock{
    MRC_LocalFileItem *item = [[MRC_LocalFileItem alloc]initWithPath:path];
    if (item.isDir) {
        failedblock([self getErrorWithDesc:@"路径非文件,请带所需未见后缀" code:-100]);
        return NO;
    }else{
        return [item mkFileWithName:item.path success:block failed:failedblock];
    }
}

- (void)copyItems:(NSArray <MRC_LocalFileItem *>*)itemArray toPath:(NSString *)destPath block:(fileOptBlock)block finish:(finishBlock)finishB{
    MRC_LocalFileItem *item = [[MRC_LocalFileItem alloc]initWithPath:destPath];
    [self copyItems:itemArray toItem:item block:block finish:finishB];
}
- (void)copyItems:(NSArray <MRC_LocalFileItem *>*)itemArray toItem:(MRC_LocalFileItem *)item block:(fileOptBlock)block finish:(finishBlock)finishB{
    if (item.isDir) {
        [self.optArray addObjectsFromArray:itemArray];
        
        __block NSMutableArray *errorArray = [NSMutableArray arrayWithCapacity:0];
        __block NSMutableArray *finishArray = [NSMutableArray arrayWithCapacity:0];
        for (MRC_LocalFileItem *citem in itemArray) {
            if ([citem isKindOfClass:[MRC_FileItem class]]) {
                [citem copyTo:item success:^(BOOL success) {
                    if (success) {
                        [finishArray addObject:citem];
                        [self.fshArray addObject:citem];
                    }else{
                        [errorArray addObject:citem];
                        [self.failArray addObject:citem];
                    }
                    
                    if(block)
                        block(errorArray.count,finishArray.count,itemArray.count);
                    
                    if (errorArray.count + finishArray.count == itemArray.count &&
                        finishB) {
                        finishB(YES,errorArray,finishArray,nil);
                    }
                    
                    if (self.listenBlock) {
                        self.listenBlock(self.failArray.count, self.fshArray.count, self.optArray.count);
                    }
                    if (self.failArray.count + self.fshArray.count == self.optArray.count) {
                        [self.failArray removeAllObjects];
                        [self.fshArray removeAllObjects];
                        [self.optArray removeAllObjects];
                    }
                    
                } failed:^(NSError * _Nonnull error) {
                    [errorArray addObject:citem];
                    [self.failArray addObject:citem];
                    if (block)
                        block(errorArray.count,finishArray.count,itemArray.count);
                    
                    if (errorArray.count + finishArray.count == itemArray.count &&
                        finishB) {
                        finishB(YES,errorArray,finishArray,nil);
                    }
                    
                    if (self.failArray.count + self.fshArray.count == self.optArray.count) {
                        [self.failArray removeAllObjects];
                        [self.fshArray removeAllObjects];
                        [self.optArray removeAllObjects];
                    }
                }];
            }else{
                [errorArray addObject:citem];
                [self.failArray addObject:citem];
                if (block)
                    block(errorArray.count,finishArray.count,itemArray.count);
                
                if (errorArray.count + finishArray.count == itemArray.count &&
                    finishB) {
                    finishB(YES,errorArray,finishArray,nil);
                }
                if (self.failArray.count + self.fshArray.count == self.optArray.count) {
                    [self.failArray removeAllObjects];
                    [self.fshArray removeAllObjects];
                    [self.optArray removeAllObjects];
                }
            }
        }
    }else
        finishB(NO,itemArray,@[],[self getErrorWithDesc:@"拷贝最终路径非文件夹" code:-100]);
}

- (void)cutItems:(NSArray <MRC_LocalFileItem *>*)itemArray toPath:(NSString *)destPath block:(fileOptBlock)block finish:(finishBlock)finishB{
    MRC_LocalFileItem *item = [[MRC_LocalFileItem alloc]initWithPath:destPath];
    [self cutItems:itemArray toItem:item block:block finish:finishB];
}
- (void)cutItems:(NSArray <MRC_LocalFileItem *>*)itemArray toItem:(MRC_LocalFileItem *)item block:(fileOptBlock)block finish:(finishBlock)finishB{
    if (item.isDir) {
        [self.optArray addObjectsFromArray:itemArray];
        __block NSMutableArray *errorArray = [NSMutableArray arrayWithCapacity:0];
        __block NSMutableArray *finishArray = [NSMutableArray arrayWithCapacity:0];
        for (MRC_LocalFileItem *citem in itemArray) {
            if ([citem isKindOfClass:[MRC_FileItem class]]) {
                [citem cutTo:item success:^(BOOL success) {
                    if (success) {
                        [finishArray addObject:citem];
                        [self.fshArray addObject:citem];
                    }else{
                        [errorArray addObject:citem];
                        [self.failArray addObject:citem];
                    }
                    
                    if(block)
                        block(errorArray.count,finishArray.count,itemArray.count);
                    
                    if (errorArray.count + finishArray.count == itemArray.count &&
                        finishB) {
                        finishB(YES,errorArray,finishArray,nil);
                    }
                    
                    if (self.listenBlock) {
                        self.listenBlock(self.failArray.count, self.fshArray.count, self.optArray.count);
                    }
                    if (self.failArray.count + self.fshArray.count == self.optArray.count) {
                        [self.failArray removeAllObjects];
                        [self.fshArray removeAllObjects];
                        [self.optArray removeAllObjects];
                    }
                    
                } failed:^(NSError * _Nonnull error) {
                    [errorArray addObject:citem];
                    [self.failArray addObject:citem];
                    if (block)
                        block(errorArray.count,finishArray.count,itemArray.count);
                    
                    if (errorArray.count + finishArray.count == itemArray.count &&
                        finishB) {
                        finishB(YES,errorArray,finishArray,nil);
                    }
                    if (self.failArray.count + self.fshArray.count == self.optArray.count) {
                        [self.failArray removeAllObjects];
                        [self.fshArray removeAllObjects];
                        [self.optArray removeAllObjects];
                    }
                }];
            }else{
                [errorArray addObject:citem];
                [self.failArray addObject:citem];
                
                if (block)
                    block(errorArray.count,finishArray.count,itemArray.count);
                
                if (errorArray.count + finishArray.count == itemArray.count &&
                    finishB) {
                    finishB(YES,errorArray,finishArray,nil);
                }
                if (self.failArray.count + self.fshArray.count == self.optArray.count) {
                    [self.failArray removeAllObjects];
                    [self.fshArray removeAllObjects];
                    [self.optArray removeAllObjects];
                }
            }
        }
    }else
        finishB(NO,itemArray,@[],[self getErrorWithDesc:@"拷贝最终路径非文件夹" code:-100]);
}

- (void)deleteItems:(NSArray <MRC_LocalFileItem *>*)itemArray block:(fileOptBlock)block finish:(finishBlock)finishB{
    __block NSMutableArray *errorArray = [NSMutableArray arrayWithCapacity:0];
    __block NSMutableArray *finishArray = [NSMutableArray arrayWithCapacity:0];
    for (MRC_LocalFileItem *citem in itemArray) {
        if ([citem isKindOfClass:[MRC_FileItem class]]) {
            [citem del:^(BOOL success) {
                if (success) {
                    [finishArray addObject:citem];
                }else{
                    [errorArray addObject:citem];
                }
                
                if(block)
                    block(errorArray.count,finishArray.count,itemArray.count);
                
                if (errorArray.count + finishArray.count == itemArray.count &&
                    finishB) {
                    finishB(YES,errorArray,finishArray,nil);
                }
            } failed:^(NSError * _Nonnull error) {
                [errorArray addObject:citem];
                if (block)
                    block(errorArray.count,finishArray.count,itemArray.count);
                
                if (errorArray.count + finishArray.count == itemArray.count &&
                    finishB) {
                    finishB(YES,errorArray,finishArray,nil);
                }
            }];
        }else{
            [errorArray addObject:citem];
            if (block)
                block(errorArray.count,finishArray.count,itemArray.count);
            
            if (errorArray.count + finishArray.count == itemArray.count &&
                finishB) {
                finishB(YES,errorArray,finishArray,nil);
            }
        }
    }
}

- (void)renameItem:(MRC_LocalFileItem *)item newName:(NSString *)name finish:(void (^)(BOOL success))block failed:(void (^)(NSError *error))failedblock{
    if (!item) {
        failedblock([self getErrorWithDesc:@"命名文件有误" code:-100]);
        return;
    }
    if (![item isKindOfClass:[MRC_FileItem class]]) {
        failedblock([self getErrorWithDesc:@"命名文件类型有误" code:-100]);
        return;
    }
    [item renameToName:name success:block failed:failedblock];
}

- (NSMutableArray *)optArray{
    if (!_optArray) {
        _optArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _optArray;
}
- (NSMutableArray *)fshArray{
    if (!_fshArray) {
        _fshArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _fshArray;
}
- (NSMutableArray *)failArray{
    if (!_failArray) {
        _failArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _failArray;
}

@end
