//
//  MRC_PrivateData.m
//  FileManagerSDK
//
//  Created by 李沛 on 2020/11/27.
//  Copyright © 2020 Mr.陈. All rights reserved.
//

#import "MRC_PrivateData.h"

@implementation MRC_PrivateData
static MRC_PrivateData *mrc_privateD = nil;
+ (instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mrc_privateD = [[self alloc] init];
    });
    return mrc_privateD;
}
- (NSArray *)musicArr
{
    if (!_musicArr)
    {
        _musicArr = @[@"mp3",@"m3u",@"m4a",@"m4b",@"m4p",@"mp2",@"mpga",@"wav",@"wma",@"ogg",@"aac",@"aiff",@"aif",@"amr",@"aob",@"ape",@"axa",@"flac",@"it",@"m2a",@"m4a",@"mka",@"mlp",@"mod",@"mp1",@"mp2",@"mpa",@"mpc",@"oga",@"oma",@"opus",@"rmi",@"s3m",@"spx",@"tta",@"tta",@"voc",@"vqf",@"wv",@"xa",@"xm"];
    }
    return _musicArr;
}
- (NSArray *)videoArr
{
    if (!_videoArr) {
        _videoArr = @[@"mp4",@"wmv",@"3gp",@"avi",@"m4u",@"m4v",@"mkv",@"mpeg",@"mpg",@"mpg4",@"rmvb",@"flv",@"3gp2",@"3gpp",@"amv",@"asf",@"axv",@"divx",@"dv",@"f4v",@"gvi",@"gxf",@"m1v",@"m2p",@"m2t",@"m2ts",@"m2v",@"m4v",@"mks",@"mkv",@"mov",@"mp2v",@"mpeg1",@"mpeg2",@"mpeg4",@"mpv",@"mt2s",@"mts",@"mxf",@"nsv",@"nuv",@"ogg",@"ogm",@"ogv",@"ogx",@"ps",@"qt",@"rec",@"rm",@"rmvb",@"tod",@"ts",@"tts",@"vob",@"vor",@"webm",@"wm",@"wtv",@"xesc"];
    }
    return _videoArr;
}
- (NSArray *)picArr
{
    if (!_picArr) {
        _picArr = @[@"png",@"jpg",@"bmp",@"pcx",@"tiff",@"gif",@"jpeg",@"fpx"];
    }
    return _picArr;
}
- (NSArray *)textArr
{
    if (!_textArr) {
        _textArr = @[@"bmp",@"doc",@"class",@"docx",@"xls",@"xlsx",@"gtar",@"gz",@"jar",@"js",@"mpc",@"msg",@"pdf",@"pps",@"ppt",@"pptx",@"tar",@"tgz",@"wps",@"z",@"txt",@"c",@"conf",@"cpp",@"h",@"htm",@"html",@"java",@"log",@"prop",@"rc",@"sh",@"xml"];
    }
    return _textArr;
}
- (NSArray *)zipArr{
    if (!_zipArr) {
        _zipArr = @[@"zip",@"rar",@"7z",@"zipx",@"zz",@"rz",@"z"];
    }
    return _zipArr;
}
- (NSArray *)htmlArr{
    if (!_htmlArr) {
        _htmlArr = @[@"html",@"htm",@"webarchive",@"dhtml",@"xhtml",@"shtm",@"shtml"];
    }
    return _htmlArr;
}
@end
