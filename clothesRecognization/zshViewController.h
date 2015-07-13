//
//  zshViewController.h
//  clothes recognization
//
//  Created by zsh tony on 14-5-25.
//  Copyright (c) 2014年 zsh-tony. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol ViewControllerDelegate <NSObject>
@optional
- (void)getSenderFromViewControllerDelegate:(UIButton *)sender;
@end

@interface zshViewController : UIViewController<UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    
	IBOutlet UIView *previewView;
	AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
	dispatch_queue_t videoDataOutputQueue;
	AVCaptureStillImageOutput *stillImageOutput;
	UIView *flashView;
	CGFloat beginGestureScale;
	CGFloat effectiveScale;
    void* network;
    void* predictor1;
    void* predictor2;
    void* predictor3;
    void* predictor4;
    void* predictor5;
    void* predictor6;
    void* predictor7;
    void* predictor8;
    void* predictor9;
    void* predictor10;
    void* predictor11;
    void* predictor12;
    void* predictor13;
    void* predictor14;
    void* predictor15;
    void* predictor16;
    void* predictor17;
    void* predictor18;
    void* predictor19;
    void* predictor20;
    void* predictor21;
    void* predictor22;
    void* predictor23;
    void* predictor24;
    void* predictor25;
    NSMutableDictionary* oldPredictionValues;
    NSMutableArray* labelLayers;
    NSMutableArray *btnarray;
    AVCaptureSession* session;
}

@property (nonatomic, retain) UIImageView * line;
@property (retain, nonatomic) CATextLayer *predictionTextLayer;
@property (nonatomic,strong) id<ViewControllerDelegate> delegate;
@property (retain, nonatomic) IBOutlet UIButton *freezebtn;
- (IBAction)takePicture:(id)sender;
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer;
@end





