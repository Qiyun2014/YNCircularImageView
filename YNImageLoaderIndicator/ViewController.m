//
//  ViewController.m
//  YNImageLoaderIndicator
//
//  Created by qiyun on 16/6/14.
//  Copyright © 2016年 qiyun. All rights reserved.
//

#import "ViewController.h"
#import "SDWebImage/SDWebImageManager.h"
#import <libkern/OSAtomic.h>

@interface ViewController ()

@property (nonatomic, strong) UILabel   *textWithImagelabel;

@end

@implementation ViewController

- (UILabel *)textWithImagelabel{
    
    if (!_textWithImagelabel) {
        
        _textWithImagelabel = [[UILabel alloc] initWithFrame:self.view.bounds];
        _textWithImagelabel.font = [UIFont systemFontOfSize:12];
        _textWithImagelabel.textColor = [UIColor blackColor];
        _textWithImagelabel.backgroundColor = [UIColor lightGrayColor];
        _textWithImagelabel.numberOfLines = 0;
    }
    return  _textWithImagelabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    return;
    
    NSString *url = @"<p>dangdangdangdangdang</p><p>duang`~</p><p><img src=\"https://github.com/Qiyun2014/YNAudioPlayerViewController/blob/master/screenShortcut/IMG_0707.PNG\" alt=\"sioihosadhohasdoih\" src=\"http://api.gandongshijie.cn/ueditor/php/upload/image/20160602/1464849372570048.png\" title=\"1464849372570048.png\"/></p> src=\"http://www.baidu.com/image/12345.png\"2344242 4243";
    
    
    [self sizeWithText:url heightOfAllImage:^(CGFloat height) {
        
        NSLog(@"height = %f",height);
        
    } complete:^{
        
        NSLog(@"完成...");
    }];
    
}

//"<p>dangdangdangdangdang</p><p>duang`~</p><p><img alt=\"\U6848\U4f8b\U5e93.png\" src=\"http://api.gandongshijie.cn/ueditor/php/upload/image/20160602/1464849372570048.png\" title=\"1464849372570048.png\"/></p>";

- (void)sizeWithText:(NSString *)text heightOfAllImage:(void (^) (CGFloat height))height complete:(void (^) (void))complete{

    OSSpinLock sLock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&sLock);
    {
        
        [self.view addSubview:self.textWithImagelabel];
        
        NSMutableArray  *ranges = [NSMutableArray array];
        NSMutableArray  *originRanges = [NSMutableArray array];
        NSMutableArray  *imageUrls = [NSMutableArray array];
        NSMutableString *mutableString = [[NSMutableString alloc] initWithString:text];
        
        NSString *regexString = @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
        
        
        
        /* 获取所有链接及其所在位置 */
        
        NSError *error;
        // 创建NSRegularExpression对象并指定正则表达式
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:regexString
                                      options:NSRegularExpressionCaseInsensitive
                                      error:&error];
        
        // 对str字符串进行匹配
        NSArray *matches = [regex matchesInString:text
                                          options:0
                                            range:NSMakeRange(0, text.length)];
        
        // 遍历匹配后的每一条记录
        for (NSTextCheckingResult *match in matches) {
            
            NSRange range = [match range];
            NSString *mStr = [text substringWithRange:range];
            //NSLog(@"%@", mStr);
            
            [imageUrls addObject:mStr];
            [ranges addObject:[NSValue valueWithRange:range]];
        }
        
        
        __block NSInteger indexLocation = 0;
        
        [ranges enumerateObjectsUsingBlock:^(NSValue *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSRange range = [obj rangeValue];
            [mutableString replaceCharactersInRange:NSMakeRange(range.location - indexLocation , range.length) withString:@""];
            
            [originRanges addObject:@(range.location - indexLocation )];
            /* 记录上一次的位置 */
            indexLocation += (range.length );
            
            //NSLog(@"~~~~~~~~  %@",mutableString);
        }];
        
        
        
        __block CGFloat heightOfAllImage = 0.0f;
        __block NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[[NSAttributedString alloc] initWithString:mutableString]];
        
        [imageUrls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:obj]
                                                            options:SDWebImageProgressiveDownload
                                                           progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                               
                                                           } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                               
                                                               UIImage *imageDownload = image?image:[UIImage imageNamed:@"bg_img.png"];
                                                               
                                                               [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n\t"]];
                                                               
                                                               NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
                                                               textAttachment.image = imageDownload;
                                                               CGSize size = [self sizeWithImage:imageDownload];
                                                               NSLog(@"size = %@",NSStringFromCGSize(size));
                                                               heightOfAllImage += size.height;

                                                               textAttachment.bounds = CGRectMake(0, 0, size.width, size.height);
                                                               [attributedString insertAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment] atIndex:[originRanges[idx] intValue]];
                                                               
                                                               [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n\t"]];
                                                               self.textWithImagelabel.textAlignment = NSTextAlignmentCenter;
                                                               self.textWithImagelabel.attributedText = attributedString;
                                                               
                                                               height(heightOfAllImage);
                                                               
                                                               if (idx == imageUrls.count - 1){
                                                                   
                                                                   if (complete) complete();
                                                               }
                                                           }];
        }];
    }
    
    OSSpinLockUnlock(&sLock);
}

- (CGSize)sizeWithImage:(UIImage *)image{
    
    CGSize size = image.size;
    CGFloat maxWidth = CGRectGetWidth(self.textWithImagelabel.frame);
    
    if (size.width < maxWidth - 20){
        
        return size;
    }else{
        
        CGFloat scale = maxWidth/size.width;
        return CGSizeMake(maxWidth, size.height * scale);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
