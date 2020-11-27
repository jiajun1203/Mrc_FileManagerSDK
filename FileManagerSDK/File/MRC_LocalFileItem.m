//
//  MRC_LocalFileItem.m
//  FileManagerSDK
//
//  Created by 陈征征 on 2020/11/25.
//
#import <Foundation/Foundation.h>
#import "MRC_LocalFileItem.h"
#import "MRC_FileTypeProtocol.h"
#import "MRC_FileManager.h"
@interface MRC_LocalFileItem()<MRC_File_protocol>
@end
@implementation MRC_LocalFileItem
-(instancetype) initWithPath:(NSString*) path{
    self = [super init];
    if (self) {
        BOOL isFind = [[MRC_FileManager shareManager]fileExistsAtPath:path];
        if (isFind) {
            self.path = path;
        }else{
            __block NSString * defaultPath = [NSString stringWithFormat:@"%@/%@",NSHomeDirectory(),@"Library/Caches"];
            NSString *name = path.lastPathComponent;
            NSString *lowPath = [NSString stringWithString:path];
            lowPath = [lowPath stringByDeletingLastPathComponent];
            self.path = lowPath;
            if (!path.pathExtension ||
                [path.pathExtension isEqualToString:@""]) {
                BOOL isSuc = [self mkDirWithName:name success:^(BOOL success, NSString * _Nonnull path) {} failed:^(NSError * _Nonnull error) {}];
                if (isSuc) {
                    self.path = path;
                }else{
                    NSLog(@"未发现文件夹,自动创建文件夹失败,文件默认路径--> %@",defaultPath);
                    self.path = defaultPath;
                }
            }else{
                BOOL isSuc = [self mkFileWithName:name success:^(BOOL success, NSString * _Nonnull path) {} failed:^(NSError * _Nonnull error) {}];
                if (isSuc) {
                    self.path = path;
                }else{
                    NSLog(@"未发现文件,自动创建文件失败,文件默认路径--> %@",defaultPath);
                    self.path = defaultPath;
                }
            }
        }
        
//        NSFileManager *fm = [NSFileManager defaultManager];
//        if ([fm fileExistsAtPath:path]) {
//            self.path = path;
//        }else{
//            self.path = [NSString stringWithFormat:@"%@/%@",NSHomeDirectory(),@"Library/Caches"];
//        }
        [self set_FileType];
    }
    return self;
}
- (NSInteger)subItemCount{
    if (self.isDir) {
        NSArray * dirArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
        return dirArray.count;
    }
    return -1;
}

//获取文件列表
-(void) listFiles:(void(^)(id fileArr))block{
    BOOL isDirectory;
    
    if (self.listFiles != nil &&
        self.listFiles.count > 0) {
        block(self.listFiles);
        return;
    }
    
    self.listFiles = [[NSMutableArray alloc]initWithCapacity:0];
    
    NSArray *paths = [[NSArray alloc]initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil]];
    for (NSString *subStr in paths){
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",self.path,subStr];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory]) {
            
            MRC_FileItem *localFile = [[MRC_LocalFileItem alloc]initWithPath:filePath];
            
            NSDictionary *firstFileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:localFile.path error:nil];
            
            NSDictionary *secondFileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:localFile.path error:nil];
            
            id firstData = [firstFileInfo objectForKey:NSFileCreationDate];//获取前一个文件修改时间
            
            id secondData = [secondFileInfo objectForKey:NSFileModificationDate];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            //设定时间格式,这里可以设置成自己需要的格式
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            
            localFile.crateDate = [dateFormatter stringFromDate:firstData];
            
            localFile.modifyDate = [dateFormatter stringFromDate:secondData];
            
            localFile.parent = self;
            
            [self.listFiles addObject:localFile];
        }
    }
    
    block(self.listFiles);
    
}
//获取目录下所有同类型文件
//-(void) getFileListOffset:(int)offset AndCount:(int)count andType:(MRC_FileType)fileType And:(void (^)(id result))block{
//    
//}
////获取当前目录 所有同类型文件
//- (void)listFiles:(void(^)(id fileArr))block FileType:(MRC_FileType)fileType{
//    
//}

//拷贝文件
- (void)copyTo:(MRC_FileItem*)dest success:(void (^)(BOOL success))block failed:(void (^)(NSError *error))failedblock{
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:self.path toPath:[dest.path stringByAppendingPathComponent:self.path.lastPathComponent] error:&error];
    if (error) {
        failedblock(error);
    }else
        block(YES);
}

//剪贴
- (void)cutTo:(MRC_FileItem*)dest success:(void (^)(BOOL success))block failed:(void (^)(NSError *error))failedblock{
    if ([[NSFileManager defaultManager]fileExistsAtPath:self.path]) {
        if ([[NSFileManager defaultManager]fileExistsAtPath:dest.path]) {
            NSError *err;
           [[NSFileManager defaultManager] moveItemAtPath:self.path toPath:[dest.path stringByAppendingPathComponent:self.path.lastPathComponent] error:&err];
            if (!err) {
                [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
                block(YES);
            }else
                failedblock(err);
        }else
            failedblock([self getErrorWithDesc:@"未找到要剪贴到的路径" code:-101]);
        
    }else{
        failedblock([self getErrorWithDesc:@"未发现需要剪贴的文件" code:-100]);
    }
}
- (NSError *)getErrorWithDesc:(NSString *)errStr code:(int)code{
    NSString *domain = @"MRC_FILE_ERROR";
    NSString *desc = errStr;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
    NSError *error = [NSError errorWithDomain:domain code:code userInfo:userInfo];
    return error;
}
//重命名
- (void)renameToName:(NSString *)name success:(void (^)(BOOL success))block failed:(void (^)(NSError *error))failedblock{
    
    NSString *str = [self.path.lastPathComponent stringByDeletingPathExtension];
    NSString *strUrl = [self.path stringByReplacingOccurrencesOfString:str withString:name];
    
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:self.path toPath:strUrl error:&error];
    if (error) {
        failedblock(error);
    }else
        block(YES);
}

//删除文件
- (void)del:(void (^)(BOOL success))block failed:(void (^)(NSError *error))failedblock{
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:&err];
    if (err) {
        failedblock(err);
    }else
        block(YES);
}

//创建文件
- (BOOL)mkDirWithName:(NSString *)name success:(void (^)(BOOL success ,NSString *path))block failed:(void (^)(NSError *error))failedblock{
//    NSString *newPath = [self.path stringByAppendingFormat:@"/%@",name];
    NSString *newPath = [self.path stringByAppendingPathComponent:name];
    NSError *err;
    BOOL isSuc = [[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&err];
    if (isSuc) {
        if (block)
            block(YES,newPath);
    }else{
        if (failedblock) {
            failedblock(err);
        }
    }
    return isSuc;
}

//创建文件
- (BOOL)mkFileWithName:(NSString *)name success:(void (^)(BOOL success ,NSString *path))block failed:(void (^)(NSError *error))failedblock{
//    NSString *newPath = [self.path stringByAppendingFormat:@"/%@",name];
    NSString *newPath = [self.path stringByAppendingPathComponent:name];
    BOOL isSuc = [[NSFileManager defaultManager]createFileAtPath:newPath contents:nil attributes:nil];
    if (isSuc) {
        if (block) {
            block(YES,newPath);
        }
    }else if (failedblock)
        failedblock(nil);
    
    return isSuc;
}

@end
