//
//  webview.h
//  webview
//
//  Created by zsh tony on 14-5-14.
//  Copyright (c) 2014年 zsh tony. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface webview : UIView
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIToolbar *topbar;
@property (strong, nonatomic)IBOutlet UIBarButtonItem *stopitem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exititem;
@property (strong, nonatomic) IBOutlet UIToolbar *bottombar;
- (IBAction)reload:(id)sender;
- (IBAction)forwrad:(id)sender;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *loadlabel;
- (IBAction)stopload:(id)sender;
- (IBAction)backward:(id)sender;
@end
