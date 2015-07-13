//
//  webview.m
//  webview
//
//  Created by zsh tony on 14-5-14.
//  Copyright (c) 2014年 zsh tony. All rights reserved.
//

#import "webview.h"

@implementation webview

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (IBAction)reload:(id)sender {
      [_webView reload];
}

- (IBAction)forwrad:(id)sender {
      [_webView goForward];
}

- (IBAction)stopload:(id)sender {
    if (_webView.loading==YES) {
        [_webView stopLoading];
        [_stopitem setImage:[UIImage imageNamed:@"-1_conew1.png"]];
        [_loadlabel setTitle:@"加载完成"];
  
    }else{
        [_webView reload];
        [_stopitem setImage:[UIImage imageNamed:@"1_conew1.png"]];
              [_loadlabel setTitle:@"加载完成"];
    }
}

- (IBAction)backward:(id)sender {
       [_webView goBack];
}
@end
