//
//  webviewViewController.m
//  webview
//
//  Created by zsh tony on 14-5-13.
//  Copyright (c) 2014年 zsh tony. All rights reserved.
//

#import "webviewViewController.h"
#import "webview.h"
#import "SVProgressHUD.h"
@interface webviewViewController ()
{
    NSString *str;
    NSURL *url;
    NSURLRequest *request;
    webview *view;
}
@end

@implementation webviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    view=[[[NSBundle mainBundle] loadNibNamed:@"webView" owner:self options:nil] lastObject];
    [self.view addSubview:view];
   [self.view setBackgroundColor:[UIColor whiteColor]];
    view.webView.delegate=self;
    [view.exititem setTarget:self];
    [view.exititem setAction:@selector(exit)];
   }
-(void)exit
{
     //Back the parentview
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)getSenderFromViewControllerDelegate:(UIButton *)sender
{
    //Get the corrsponding IP address depending on the tag
    switch (sender.tag) {
        case 1:
            
            str=@"http://s.taobao.com/search?q=basichouse_HMCA723A&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";

            break;
            
        case 2:
            str=@"http://s.taobao.com/search?q=basichouse_HMJP226C&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            
            break;
        case 3:
            str=@"http://s.taobao.com/search?q=only_113427003&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";

            break;
        case 4:
            str=@"http://s.taobao.com/search?q=only_113327005&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 5:
            str=@"http://s.taobao.com/search?q=only_113327021&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 6:
            str=@"http://s.taobao.com/search?initiative_id=staobaoz_20140524&js=1&q=only_113327003&stats_click=search_radio_all%3A1";
            break;
        case 7:
            str=@"http://s.taobao.com/search?q=zara_0706_326&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 8:
            str=@"http://s.taobao.com/search?q=zara_0706_319&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 9:
            str=@"http://s.taobao.com/search?q=zara_1608_303&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 10:
            str=@"http://s.taobao.com/search?q=zara_0693_329&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 11:
            str=@"http://s.taobao.com/search?q=zara_0706_304&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 12:
            str=@"http://s.taobao.com/search?q=zara_6096_451&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 13:
            str=@"http://s.taobao.com/search?q=jackjones_213427006&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 14:
            str=@"http://s.taobao.com/search?q=Jack+Jone212427006&s_from=newHeader&ssid=s5-e&search_type=item&sourceId=tb.item";
            break;
        case 15:
            str=@"http://s.taobao.com/search?q=jackjones_212408029&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 16:
            str=@"http://s.taobao.com/search?q=jackjones_212427021&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 17:
            str=@"http://s.taobao.com/search?initiative_id=staobaoz_20140524&js=1&q=%BD%DC%BF%CB%C7%ED%CB%B9212427019&stats_click=search_radio_all%3A1";
            break;
        case 18:
            str=@"http://s.taobao.com/search?q=jackjones_212427017&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 19:
            str=@"http://s.taobao.com/search?initiative_id=staobaoz_20140524&js=1&q=selected_412427040&stats_click=search_radio_all%3A1";
            break;
        case 20:
            str=@"http://s.taobao.com/search?q=selected_412427014&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 21:
            str=@"http://s.taobao.com/search?q=selected_412427048&app=detail";
            break;
        case 22:
            str=@"http://s.taobao.com/search?initiative_id=staobaoz_20140524&js=1&q=veromode_313427011&stats_click=search_radio_all%3A1";
            break;
        case 23:
            str=@"http://s.taobao.com/search?q=veromode_313427012&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
        case 24:
            str=@"http://s.taobao.com/search?q=veromode_312427014&app=detail";
            break;
        case 25:
            str=@"http://s.taobao.com/search?q=veromode_313327003&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=1.7274553.1997520841.1&initiative_id=tbindexz_20140524";
            break;
       
        
    }
    //loading the IP on the webview
    url = [NSURL URLWithString:str];
    request = [NSURLRequest requestWithURL:url];
    [view.webView setDataDetectorTypes:UIDataDetectorTypeAll];
    [view.webView loadRequest:request];
    

    
}

#pragma mark - UIWebViewDelegate的实现
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    //configure the icon of the stop btn
        [view.stopitem setImage:[UIImage imageNamed:@"-1_conew1.png"]];
        [view.loadlabel setTitle:@"加载中"];
    //display the state of loading
        [SVProgressHUD showWithStatus:@"加载中" maskType:SVProgressHUDMaskTypeNone];
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //alter the icon to reflesh
       [view.stopitem setImage:[UIImage imageNamed:@"1_conew1.png"]];
       [view.loadlabel setTitle:@"加载完成"];
       [SVProgressHUD dismiss];
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"加载出错%@", [error localizedDescription]);
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"网络加载失败"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"再试一次"
                                          otherButtonTitles:@"取消", nil];
  [alert show];
    
}
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //if you click the button of trying again
    if (buttonIndex==0) {
        url = [NSURL URLWithString:str];
        request = [NSURLRequest requestWithURL:url];
        [view.webView setDataDetectorTypes:UIDataDetectorTypeAll];
        [view.webView loadRequest:request];
    }

    [SVProgressHUD dismiss];
}

@end
