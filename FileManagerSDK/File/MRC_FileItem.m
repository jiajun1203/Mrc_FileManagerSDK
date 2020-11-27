//
//  MRC_FileItem.m
//  FileManagerSDK
//
//  Created by 陈征征 on 2020/11/25.
//

#import "MRC_FileItem.h"
#import "MRC_FileTypeProtocol.h"
#import "MRC_PrivateData.h"
typedef void (^MrcDataBlock)(id result);

@interface MRC_FileItem()<MRC_File_protocol>
@property (nonatomic ,copy) MrcDataBlock mblock;
@end
@implementation MRC_FileItem
-(instancetype) initWithPath:(NSString*) path{
    self = [super init];
    if (self) {
        [self set_FileType];
    }
    return self;
}
- (NSString *)fileName{
    return self.path.lastPathComponent;
}
- (BOOL)isDir{
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory];
    return isDirectory;
}
- (long long)totalSize{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:self.path]){
        return [[manager attributesOfItemAtPath:self.path error:nil] fileSize];
    }
    return 0;
}
- (NSString *)totalSizeString{
           if (self.totalSize >= 1024*1024*1024) {
               return [NSString stringWithFormat:@"%.2fG",self.totalSize/(1024*1024*1024.0)];
           }else if (self.totalSize >= 1024*1024) {
               return [NSString stringWithFormat:@"%.2fM",self.totalSize/(1024*1024.0)];
           }else if(self.totalSize>0){
               return [NSString stringWithFormat:@"%.0fK",self.totalSize/1024.0];
           }else{
               return @"";
           }
//    return [NSByteCountFormatter stringFromByteCount:self.totalSize countStyle:NSByteCountFormatterCountStyleBinary];
;
}
- (void)set_FileType{
    
    if ([self isHasItemWithItem:self AndData:[MRC_PrivateData shareManager].musicArr])
        _fileType = FILE_MRC_MUSIC;
    else if ([self isHasItemWithItem:self AndData:[MRC_PrivateData shareManager].videoArr])
        _fileType = FILE_MRC_VIDEO;
    else if ([self isHasItemWithItem:self AndData:[MRC_PrivateData shareManager].picArr])
        _fileType = FILE_MRC_PICTURE;
    else if ([self isHasItemWithItem:self AndData:[MRC_PrivateData shareManager].textArr])
        _fileType = FILE_MRC_TEXT;
    else if ([self isHasItemWithItem:self AndData:[MRC_PrivateData shareManager].zipArr])
        _fileType = FILE_MRC_ZIP;
    else if ([self isHasItemWithItem:self AndData:[MRC_PrivateData shareManager].htmlArr])
        _fileType = FILE_MRC_LINK;
    else
    {
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory];
        if (isDirectory) {
            _fileType = FILE_MRC_DIR;
        }else
            _fileType = FILE_MRC_UNKNOW;
    }
}
//- (MRC_FileType)fileType{
//    if (_fileType == FILE_MRC_UNKNOW) {
//        if ([self isHasItemWithItem:self AndData:self.musicArr])
//            _fileType = FILE_MRC_MUSIC;
//        else if ([self isHasItemWithItem:self AndData:self.videoArr])
//            _fileType = FILE_MRC_VIDEO;
//        else if ([self isHasItemWithItem:self AndData:self.picArr])
//            _fileType = FILE_MRC_PICTURE;
//        else if ([self isHasItemWithItem:self AndData:self.textArr])
//            _fileType = FILE_MRC_TEXT;
//        else
//        {
//            _fileType = FILE_MRC_UNKNOW;
//        }
//    }
//    return _fileType;
//}
-(BOOL)isFileType:(MRC_FileItem *) fileItem fileType:(MRC_FileType ) fileType
{
    
    NSArray *arr = nil;
    
    switch (fileType) {
            
        case FILE_MRC_MUSIC:
            arr = [MRC_PrivateData shareManager].musicArr;
            break;
        case FILE_MRC_VIDEO:
            arr = [MRC_PrivateData shareManager].videoArr;
            break;
        case FILE_MRC_PICTURE:
            arr = [MRC_PrivateData shareManager].picArr;
            break;
        case FILE_MRC_TEXT:
            arr = [MRC_PrivateData shareManager].textArr;
            break;
        case FILE_MRC_ZIP:
            arr = [MRC_PrivateData shareManager].zipArr;
            break;
        case FILE_MRC_LINK:
            arr = [MRC_PrivateData shareManager].htmlArr;
            break;
        default:
            arr = @[];
            
            
    }
    
    if (arr.count == 0) {
        return YES;
    }
    
    if ([arr containsObject:fileItem.path.pathExtension.lowercaseString]) {
        return YES;
    }
    
    return NO;
}
- (void)clearCache{
    [self.listFiles removeAllObjects];
}
//获取文件列表
-(void) listFiles:(void(^)(id fileArr))block{
    
}
//获取目录下所有同类型文件
-(void) getFileListOffset:(int)offset AndCount:(int)count andType:(MRC_FileType)fileType And:(void (^)(id result))block{
    if(!self.mblock)
        self.mblock = block;
    
    if(count <=0)
        return;
    
    
    NSMutableArray *list = [[NSMutableArray alloc]init];
    
//    __block MRC_FileItem *fileItem = self;
    
    [self listFiles:^(id fileArr) {
        //
        int offSet = offset;
        
        int counts = count;
        
        if ([fileArr isKindOfClass:[NSArray class]]) {
            
            for (int i = 0; i < [fileArr count]; i++) {
                MRC_FileItem *items = fileArr[i];
                
                if(items.fileType == fileType)
                {
                    offSet--;
                    
                    if(offSet <0 )
                    {
                        [list addObject:items];
                        counts--;
                        
                        if(count <0)
                        {
                            break;
                        }
                    }
                }
                
                if (items.isDir == YES) {
                    [items getFileListOffset:offSet AndCount:counts andType:fileType And:^(id result) {
                        [list addObjectsFromArray:result];
                    }];
                }
//                else
//                {
//                    if(items.fileType == fileType)
//                    {
//                        offSet--;
//
//                        if(offset <0 )
//                        {
//                            [list addObject:items];
//                            counts--;
//
//                            if(count <0)
//                            {
//                                break;
//                            }
//                        }
//                    }
//                }
            }
            if (list.count>0){
                self.mblock(list);
                self.mblock = nil;
            }
        }
    }];
}
//获取当前目录 所有同类型文件
- (void)listFiles:(void(^)(id fileArr))block FileType:(MRC_FileType)fileType{
    __block MRC_FileItem *items = self;
    
    if(self.listFiles == nil || [self.listFiles count] == 0)
    {
        [self listFiles:^(id fileArr) {
            if ([fileArr isKindOfClass:[NSArray class]])
                block([items getSameFileItemWithArr:fileArr AndType:fileType]);
        }];
    }else
    {
        block([self getSameFileItemWithArr:self.listFiles AndType:fileType]);
    }
}
//获取数组内所有相同类型的文件(和 调取的item同类型)
-(NSArray *)listSameTypeItemFilesWith:(NSArray *)itemArr{
    return [self getSameFileItemWithArr:itemArr AndType:self.fileType];
}

- (NSArray *)getSameFileItemWithArr:(NSArray *)fileArr AndType:(MRC_FileType)fileType
{
    NSMutableArray *filterFiles = [[NSMutableArray alloc]init];
    for (int i = 0; i < [fileArr count]; i++) {
        
        MRC_FileItem *item = fileArr[i];
        
        if (item.fileType == fileType) {
            [filterFiles addObject:item];
        }
        
//        switch (fileType) {
//            case FILE_MRC_MUSIC:
//            {
//                if ([self isHasItemWithItem:item AndData:[MRC_PrivateData shareManager].musicArr]) {
//                    [filterFiles addObject:item];
//                }
//            }
//                break;
//            case FILE_MRC_VIDEO:
//            {
//                if ([self isHasItemWithItem:item AndData:[MRC_PrivateData shareManager].videoArr]) {
//                    [filterFiles addObject:item];
//                }
//            }
//                break;
//            case FILE_MRC_PICTURE:
//            {
//                if ([self isHasItemWithItem:item AndData:[MRC_PrivateData shareManager].picArr]) {
//                    [filterFiles addObject:item];
//                }
//            }
//                break;
//            case FILE_MRC_TEXT:
//            {
//                if ([self isHasItemWithItem:item AndData:[MRC_PrivateData shareManager].textArr]) {
//                    [filterFiles addObject:item];
//                }
//            }
//                break;
//            case FILE_MRC_ZIP:
//            {
//                if ([self isHasItemWithItem:item AndData:[MRC_PrivateData shareManager].zipArr]) {
//                    [filterFiles addObject:item];
//                }
//            }
//                break;
//            case FILE_MRC_LINK:
//            {
//                if ([self isHasItemWithItem:item AndData:[MRC_PrivateData shareManager].htmlArr]) {
//                    [filterFiles addObject:item];
//                }
//            }
//                break;
//            case FILE_MRC_UNKNOW:
//            {
//                [filterFiles addObject:item];
//            }
//                break;
//
//            default:
//                break;
//        }
    }
    
    return [[NSArray alloc]initWithArray:filterFiles];
}
//拷贝文件
- (void)copyTo:(MRC_FileItem*)dest success:(void (^)(BOOL success))block failed:(void (^)(NSError *error))failedblock{
    
}

//剪贴
- (void)cutTo:(MRC_FileItem*)dest success:(void (^)(BOOL success))block failed:(void (^)(NSError *error))failedblock{
    
}

//重命名
- (void)renameToName:(NSString *)name success:(void (^)(BOOL success))block failed:(void (^)(NSError *error))failedblock{
    
}

//删除文件
- (void)del:(void (^)(BOOL success))block failed:(void (^)(NSError *error))failedblock{
    
}

- (BOOL)mkDirWithName:(NSString *)name success:(void (^)(BOOL success ,NSString *path))block failed:(void (^)(NSError *error))failedblock{
    return NO;
}

//创建文件
- (BOOL)mkFileWithName:(NSString *)name success:(void (^)(BOOL success ,NSString *path))block failed:(void (^)(NSError *error))failedblock{
    return NO;
}


- (BOOL)isHasItemWithItem:(MRC_FileItem *)item AndData:(NSArray *)arr
{
    
    if ([arr containsObject:item.path.pathExtension.lowercaseString]) {
        return YES;
    }
    return NO;
}


@end
