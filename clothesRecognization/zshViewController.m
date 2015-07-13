//
//  zshViewController.m
//  clothes recognization
//
//  Created by zsh tony on 14-5-25.
//  Copyright (c) 2014年 zsh-tony. All rights reserved.
//

#import "zshViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#include <sys/time.h>
#import "webviewViewController.h"
#import <DeepBelief/DeepBelief.h>
#import "btnsender.h"


#pragma mark-

static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

@interface zshViewController ()
{
    webviewViewController *webcontrol;
    int num;
    BOOL upOrdown;
    NSTimer * timer;
}
@end

#pragma mark-

@interface zshViewController(InternalMethods)
- (void)setupAVCapture;
- (void)teardownAVCapture;
@end

@implementation zshViewController
#pragma mark - 摄像头捕获图片
- (void)setupAVCapture
{
	NSError *error = nil;
	//Build the AVCaptureSession
	session = [AVCaptureSession new];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	    [session setSessionPreset:AVCaptureSessionPreset640x480];
	else
	    [session setSessionPreset:AVCaptureSessionPresetPhoto];
	
    // Select a video device
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	require( error == nil, bail );
	
	if ( [session canAddInput:deviceInput] )
		[session addInput:deviceInput];
	
    // Make a still image output
	stillImageOutput = [AVCaptureStillImageOutput new];
	[stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:AVCaptureStillImageIsCapturingStillImageContext];
	if ( [session canAddOutput:stillImageOutput] )
		[session addOutput:stillImageOutput];
	
    // Make a video data output
	videoDataOutput = [AVCaptureVideoDataOutput new];
	
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
	NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
									   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	[videoDataOutput setVideoSettings:rgbOutputSettings];
	[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // 丢帧处理方式
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
	videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
	[videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
	
    if ( [session canAddOutput:videoDataOutput] )
		[session addOutput:videoDataOutput];
	[[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
	effectiveScale = 1.0;
    //Add the session to the preview's rootlayer，and configure the property
	previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	[previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	CALayer *rootLayer = [previewView layer];
	[rootLayer setMasksToBounds:YES];
	[previewLayer setFrame:[rootLayer bounds]];
	[rootLayer addSublayer:previewLayer];
	[session startRunning];
    
bail:
	[session release];
	if (error) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"Dismiss"
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		[self teardownAVCapture];
	}
}

// clean up capture setup
- (void)teardownAVCapture
{
	[videoDataOutput release];
	if (videoDataOutputQueue)
		dispatch_release(videoDataOutputQueue);
	[stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
	[stillImageOutput release];
	[previewLayer removeFromSuperlayer];
	[previewLayer release];
}

#pragma mark - 自定义对象网络数据的导入并进行预测
 //Implement the callback of the video data output
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    [self runCNNOnFrame:pixelBuffer];
}

- (void)runCNNOnFrame: (CVPixelBufferRef) pixelBuffer
{

    assert(pixelBuffer != NULL);
	OSType sourcePixelFormat = CVPixelBufferGetPixelFormatType( pixelBuffer );
    int doReverseChannels;
	if ( kCVPixelFormatType_32ARGB == sourcePixelFormat ) {
        doReverseChannels = 1;
	} else if ( kCVPixelFormatType_32BGRA == sourcePixelFormat ) {
        doReverseChannels = 0;
	} else {
        assert(false); // Unknown source format
    }
    
    //Get the format of pixelBuffer，the number of bytes per row of the pixel buffer，width and fullHeight
	const int sourceRowBytes = (int)CVPixelBufferGetBytesPerRow( pixelBuffer );
	const int width = (int)CVPixelBufferGetWidth( pixelBuffer );
	const int fullHeight = (int)CVPixelBufferGetHeight( pixelBuffer );
	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
	unsigned char* sourceBaseAddr = CVPixelBufferGetBaseAddress( pixelBuffer );
    int height;
    unsigned char* sourceStartAddr;
    if (fullHeight <= width) {
        height = fullHeight;
        sourceStartAddr = sourceBaseAddr;
    } else {
        height = width;
        const int marginY = ((fullHeight - width) / 2);
        sourceStartAddr = (sourceBaseAddr + (marginY * sourceRowBytes));
    }
    
    //Get the image object
    void* cnnInput = jpcnn_create_image_buffer_from_uint8_data(sourceStartAddr, width, height, 4, sourceRowBytes, doReverseChannels, 1);
    float* predictions;
    int predictionsLength;
    int predictionsLabelsLength;
    char** predictionsLabels;
    
    //Get the predictions and predictionsLength under which layoff is -2
    jpcnn_classify_image(network, cnnInput,JPCNN_RANDOM_SAMPLE , -2, &predictions, &predictionsLength, &predictionsLabels, &predictionsLabelsLength);

    jpcnn_destroy_image_buffer(cnnInput);
    //Get the values for the customed object
    const float predictionValue1 = jpcnn_predict(predictor1, predictions, predictionsLength);
    NSMutableDictionary* values = [NSMutableDictionary
                                   dictionaryWithObject: [NSNumber numberWithFloat: predictionValue1]
                                   forKey: @"女装_basichouse_HMCA723A"];
    const float predictionValue2 = jpcnn_predict(predictor2, predictions, predictionsLength);

    [values setObject:[NSNumber numberWithFloat: predictionValue2]
               forKey:@"女装_basichouse_HMJP226C"];
    const float predictionValue3 = jpcnn_predict(predictor3, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue3]
               forKey:@"女装_only_113427003"];

    const float predictionValue4 = jpcnn_predict(predictor4, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue4]
               forKey:@"女装_only_113327005"];
    
    const float predictionValue5 = jpcnn_predict(predictor5, predictions, predictionsLength);
    
        [values setObject:[NSNumber numberWithFloat: predictionValue5]
                   forKey:@"女装_only_113327021"];

    const float predictionValue6 = jpcnn_predict(predictor6, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue6]
               forKey:@"女装_only_113327003"];
    
    const float predictionValue7 = jpcnn_predict(predictor7, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue7]
               forKey:@"男装_zara_0706_326"];
    
    const float predictionValue8 = jpcnn_predict(predictor8, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue8]
               forKey:@"男装_zara_0706_319"];
    
    const float predictionValue9 = jpcnn_predict(predictor9, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue9]
               forKey:@"男装_zara_1608_303"];
    
    const float predictionValue10 = jpcnn_predict(predictor10, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue10]
               forKey:@"男装_zara_0693_329"];
    
    const float predictionValue11 = jpcnn_predict(predictor11, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue11]
               forKey:@"男装_zara_0706_304"];
    
    const float predictionValue12 = jpcnn_predict(predictor12, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue12]
               forKey:@"男装_zara_6096_451"];
    
    const float predictionValue13 = jpcnn_predict(predictor13, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue13]
               forKey:@"男装_jackjones_213427006"];
    
    const float predictionValue14 = jpcnn_predict(predictor14, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue14]
               forKey:@"男装_jackjones_212427006"];
    
    const float predictionValue15 = jpcnn_predict(predictor15, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue15]
               forKey:@"男装_jackjones_212408029"];
    
    const float predictionValue16 = jpcnn_predict(predictor16, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue16]
               forKey:@"男装_jackjones_212427021"];
    
    const float predictionValue17 = jpcnn_predict(predictor17, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue17]
               forKey:@"男装_jackjones_212427019"];
    
    const float predictionValue18 = jpcnn_predict(predictor18, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue18]
               forKey:@"男装_jackjones_212427017"];
    
    const float predictionValue19 = jpcnn_predict(predictor19, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue19]
               forKey:@"男装_selected_412427040"];
    
    const float predictionValue20 = jpcnn_predict(predictor20, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue20]
               forKey:@"男装_selected_412427014"];
    
    const float predictionValue21 = jpcnn_predict(predictor21, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue21]
               forKey:@"男装_selected_412427048"];
    
    const float predictionValue22 = jpcnn_predict(predictor22, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue22]
               forKey:@"女装_veromode_313427011"];
    
    const float predictionValue23 = jpcnn_predict(predictor23, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue23]
               forKey:@"女装_veromode_313427012"];
    
    const float predictionValue24 = jpcnn_predict(predictor24, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue24]
               forKey:@"女装_veromode_312427014"];
    
    const float predictionValue25 = jpcnn_predict(predictor25, predictions, predictionsLength);
    
    [values setObject:[NSNumber numberWithFloat: predictionValue25]
               forKey:@"女装_veromode_313327003"];
    
      dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self setPredictionValues: values];
    });
 
}


#pragma mark - 显示预测值
- (void) setPredictionValues: (NSDictionary*) newValues {
       const float decayValue = 0.0f;
    
    //Update the oldpredictionvalues
    const float updateValue = 1.0f;
        const float minimumThreshold = 0.01f;
        NSMutableDictionary* decayedPredictionValues = [[NSMutableDictionary alloc] init];
        for (NSString* label in oldPredictionValues) {
            NSNumber* oldPredictionValueObject = [oldPredictionValues objectForKey:label];
            const float oldPredictionValue = [oldPredictionValueObject floatValue];
            const float decayedPredictionValue = (oldPredictionValue * decayValue);
            if (decayedPredictionValue > minimumThreshold) {
                NSNumber* decayedPredictionValueObject = [NSNumber numberWithFloat: decayedPredictionValue];
                [decayedPredictionValues setObject: decayedPredictionValueObject forKey:label];
            }
       }
    
        [oldPredictionValues release];
        oldPredictionValues = decayedPredictionValues;
    
    for (NSString* label in newValues) {
        NSNumber* newPredictionValueObject = [newValues objectForKey:label];
        NSNumber* oldPredictionValueObject = [oldPredictionValues objectForKey:label];
        if (!oldPredictionValueObject) {
            oldPredictionValueObject = [NSNumber numberWithFloat: 0.0f];
        }
        const float newPredictionValue = [newPredictionValueObject floatValue];
        const float oldPredictionValue = [oldPredictionValueObject floatValue];
        const float updatedPredictionValue = (oldPredictionValue + (newPredictionValue * updateValue));
        NSNumber* updatedPredictionValueObject = [NSNumber numberWithFloat: updatedPredictionValue];
        [oldPredictionValues setObject: updatedPredictionValueObject forKey:label];
    }
    
    //descend the oldpredictionvalues depending on the values
    NSArray* candidateLabels = [NSMutableArray array];
    for (NSString* label in oldPredictionValues) {
        NSNumber* oldPredictionValueObject = [oldPredictionValues objectForKey:label];
        const float oldPredictionValue = [oldPredictionValueObject floatValue];
        if (oldPredictionValue > 0.05f) {
            NSDictionary *entry = @{
                                    @"label" : label,
                                    @"value" : oldPredictionValueObject
                                    };
            candidateLabels = [candidateLabels arrayByAddingObject: entry];
        }
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"value" ascending:NO];
    NSArray* sortedLabels = [candidateLabels sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    
    const float labelWidth = 300.0f,labelHeight = 79.0f;
    int labelCount = 0;
    
    for (NSDictionary* entry in sortedLabels) {
        NSString* label = [entry objectForKey: @"label"];
        NSNumber* valueObject =[entry objectForKey: @"value"];
        const float value = [valueObject floatValue];
        const float originY = 200.0f;
        //NSLog(@"%@",value);
        //Outputed when the values > 95%
        if (labelCount==0&&value > 0.95f) {
            
            [self capturepicture];
           // NSLog(@"%@",label);
            [self addbtnLayerWithText:label
                              originX: 15 originY: originY
                                width: labelWidth height: labelHeight
                            alignment:kCAAlignmentCenter];
            
            break;
        }
        
        labelCount += 1;
        if (labelCount > 4) {
            break;
        }
    }
    
}


//- (void) addLabelLayerWithText: (NSString*) text
//                       originX:(float) originX originY:(float) originY
//                         width:(float) width height:(float) height
//                     alignment:(NSString*) alignment
//{
//    NSString* const font = @"Menlo-Regular";
//    const float fontSize = 20.0f;
//
//    const float marginSizeX = 5.0f;
//    const float marginSizeY = 2.0f;
//
//    const CGRect backgroundBounds = CGRectMake(originX, originY, width, height);
//
//    const CGRect textBounds = CGRectMake((originX + marginSizeX), (originY + marginSizeY),
//                                         (width - (marginSizeX * 2)), (height - (marginSizeY * 2)));
//
//    CATextLayer* background = [CATextLayer layer];
//    [background setBackgroundColor: [UIColor blackColor].CGColor];
//    [background setOpacity:0.5f];
//    [background setFrame: backgroundBounds];
//    background.cornerRadius = 5.0f;
//
//    [[self.view layer] addSublayer: background];
//    [labelLayers addObject: background];
//
//    [[self.view layer] addSublayer: background];
//    [labelLayers addObject: background];
//
//    CATextLayer *layer = [CATextLayer layer];
//    [layer setForegroundColor: [UIColor whiteColor].CGColor];
//    [layer setFrame: textBounds];
//    [layer setAlignmentMode: alignment];
//    [layer setWrapped: YES];
//    [layer setFont: font];
//    [layer setFontSize: fontSize];
//    layer.contentsScale = [[UIScreen mainScreen] scale];
//    [layer setString: text];
//
//    [[self.view layer] addSublayer: layer];
//
//    [labelLayers addObject: layer];
//}
- (void) addbtnLayerWithText: (NSString*) text
                     originX:(float) originX originY:(float) originY
                       width:(float) width height:(float) height
                   alignment:(NSString*) alignment
{
    //Configuring the property of the btn to be added
    NSString* const font = @"Menlo-Regular";
    
    const float fontSize = 20.0f;
    const float marginSizeX = 5.0f;
    const float marginSizeY = 2.0f;
    
    const CGRect backgroundBounds = CGRectMake(originX, originY, width, height);
    const CGRect textBounds = CGRectMake((originX + marginSizeX), (originY + marginSizeY),                                         (width - (marginSizeX * 2)), (height - (marginSizeY * 2)));
    
    //Build the btnsender object and init
    btnsender *btn = [[btnsender alloc]init];
    [btn.layer setBackgroundColor:[UIColor blackColor].CGColor];
    [btn.layer setOpacity:0.5f];
    [btn.layer setFrame:backgroundBounds];
    btn.layer.cornerRadius=5.0f;
    [btn addTarget:self action:@selector(btn:) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *tag=[btn.btndict objectForKey:text];
    btn.tag=[tag intValue];
    if (btnarray.count==0) {
        [btnarray addObject: btn];
        [self.view addSubview:btn];
    }
    
    
    //add the text when recognizes done
    CATextLayer *layer = [CATextLayer layer];
    [layer setForegroundColor: [UIColor whiteColor].CGColor];
    [layer setFrame: textBounds];
    [layer setAlignmentMode: alignment];
    [layer setWrapped: YES];
    [layer setFont: font];
    [layer setFontSize: fontSize];
    layer.contentsScale = [[UIScreen mainScreen] scale];
    NSString *textstr=[NSString stringWithFormat:@"识别成功\n%@\n 猛戳我查看宝贝详情！",text];
    [layer setString: textstr];
    if (labelLayers.count==0) {
        [[self.view layer] addSublayer: layer];
        [labelLayers addObject: layer];
    }
    
    
}

-(void)btn:(UIButton *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        [self presentViewController:webcontrol animated:YES completion:^{
        }];
        self.delegate=webcontrol;
        [self.delegate getSenderFromViewControllerDelegate:sender];
    });
}

-(void)capturepicture
{
    if ([session isRunning]) {
        [session stopRunning];
        if ([timer isValid]) {
            [timer invalidate];
        }
        [_line removeFromSuperview];
        [_freezebtn setTitle: @"继续" forState:UIControlStateNormal];
        //add the flashview and configure the alpha to generate the animation of capture picture
        flashView = [[UIView alloc] initWithFrame:[previewView frame]];
        [flashView setBackgroundColor:[UIColor whiteColor]];
        [flashView setAlpha:0.f];
        [[[self view] window] addSubview:flashView];
        
        [UIView animateWithDuration:.2f
                         animations:^{
                             [flashView setAlpha:1.f];
                         }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:.2f
                                              animations:^{
                                                  [flashView setAlpha:0.f];
                                              }
                                              completion:^(BOOL finished){
                                                  [flashView removeFromSuperview];
                                                  [flashView release];
                                                  flashView = nil;
                                              }
                              ];
                         }
         ];
        
    }
    
}


#pragma mark - 扫描状态的添加
- (void)scan
{
    upOrdown = NO;
    num =0;
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, 320, 2)];
    _line.image = [UIImage imageNamed:@"line.png"];
    [self.view addSubview:_line];
    //Init a timer to record the interval
    timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation1) userInfo:nil repeats:YES];
}

-(void)animation1
{
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(0, 20+2*num, 320, 2);
        if (2*num == 450) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame = CGRectMake(0, 20+2*num, 320, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }
    
}


#pragma mark - 添加暂停与继续的控制按钮
- (IBAction)takePicture:(id)sender {
    if ([session isRunning]) {
        [session stopRunning];
        if ([timer isValid]) {
            [timer invalidate];
        }
        [_line removeFromSuperview];
        [sender setTitle: @"继续" forState:UIControlStateNormal];
        
        flashView = [[UIView alloc] initWithFrame:[previewView frame]];
        [flashView setBackgroundColor:[UIColor whiteColor]];
        [flashView setAlpha:0.f];
        [[[self view] window] addSubview:flashView];
        
        [UIView animateWithDuration:.2f
                         animations:^{
                             [flashView setAlpha:1.f];
                         }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:.2f
                                              animations:^{
                                                  [flashView setAlpha:0.f];
                                              }
                                              completion:^(BOOL finished){
                                                  [flashView removeFromSuperview];
                                                  [flashView release];
                                                  flashView = nil;
                                              }
                              ];
                         }
         ];
        
    }
    else {
        [session startRunning];
        [sender setTitle: @"暂停" forState:UIControlStateNormal];
        [self scan];
        [self removeAllLabelLayers];
    }
}

- (void) removeAllLabelLayers {
    for (CATextLayer* layer in labelLayers) {
        [layer removeFromSuperlayer];
    }
    for (btnsender *btn in  btnarray) {
        [btn removeFromSuperview];
    }
    
    [btnarray removeAllObjects];
    [labelLayers removeAllObjects];
}


#pragma mark - 视图初始化
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (webcontrol==nil) {
        webcontrol= [[webviewViewController alloc] init];
    }
  
    NSString* networkPath = [[NSBundle mainBundle] pathForResource:@"jetpac" ofType:@"ntwk"];
    if (networkPath == NULL) {
        fprintf(stderr, "Couldn't find the neural network parameters file - did you add it as a resource to your application?\n");
        assert(false);
    }
    //Build a new network
    network = jpcnn_create_network([networkPath UTF8String]);
    assert(network != NULL);
    //Build the corresponding predictor througout the customed data from the resourse
    NSString* predictorPath1 = [[NSBundle mainBundle] pathForResource:@"basichouse_HMCA723A" ofType:@"txt"];
    if (predictorPath1 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor1 = jpcnn_load_predictor([predictorPath1 UTF8String]);
    assert(predictor1 != NULL);
    NSString* predictorPath2 = [[NSBundle mainBundle] pathForResource:@"basichouse_HMJP226C" ofType:@"txt"];
    if (predictorPath2 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor2 = jpcnn_load_predictor([predictorPath2 UTF8String]);
    assert(predictor2 != NULL);
    
    NSString* predictorPath3 = [[NSBundle mainBundle] pathForResource:@"only_113427003" ofType:@"txt"];
    if (predictorPath3 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor3 = jpcnn_load_predictor([predictorPath3 UTF8String]);
    assert(predictor3 != NULL);
    NSString* predictorPath4 = [[NSBundle mainBundle] pathForResource:@"only_113327005" ofType:@"txt"];
    if (predictorPath4 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor4 = jpcnn_load_predictor([predictorPath4 UTF8String]);
    assert(predictor4 != NULL);
    NSString* predictorPath5 = [[NSBundle mainBundle] pathForResource:@"only_113327021" ofType:@"txt"];
    if (predictorPath5 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor5 = jpcnn_load_predictor([predictorPath5 UTF8String]);
    assert(predictor5 != NULL);
    
    NSString* predictorPath6 = [[NSBundle mainBundle] pathForResource:@"only_113327003" ofType:@"txt"];
    if (predictorPath6 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor6 = jpcnn_load_predictor([predictorPath6 UTF8String]);
    assert(predictor6 != NULL);
    
    NSString* predictorPath7 = [[NSBundle mainBundle] pathForResource:@"zara_0706_326" ofType:@"txt"];
    if (predictorPath7 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor7 = jpcnn_load_predictor([predictorPath7 UTF8String]);
    assert(predictor7 != NULL);
    
    NSString* predictorPath8 = [[NSBundle mainBundle] pathForResource:@"zara_0706_319" ofType:@"txt"];
    if (predictorPath8 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor8 = jpcnn_load_predictor([predictorPath8 UTF8String]);
    assert(predictor8 != NULL);
    
    NSString* predictorPath9 = [[NSBundle mainBundle] pathForResource:@"zara_1608_303" ofType:@"txt"];
    if (predictorPath9 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor9 = jpcnn_load_predictor([predictorPath9 UTF8String]);
    assert(predictor9 != NULL);
    
    NSString* predictorPath10 = [[NSBundle mainBundle] pathForResource:@"zara_0693_329" ofType:@"txt"];
    if (predictorPath10 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor10 = jpcnn_load_predictor([predictorPath10 UTF8String]);
    assert(predictor10 != NULL);
    
    NSString* predictorPath11 = [[NSBundle mainBundle] pathForResource:@"zara_0706_304" ofType:@"txt"];
    if (predictorPath11 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor11 = jpcnn_load_predictor([predictorPath11 UTF8String]);
    assert(predictor11 != NULL);
    
    NSString* predictorPath12 = [[NSBundle mainBundle] pathForResource:@"zara_6096_451" ofType:@"txt"];
    if (predictorPath12 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor12 = jpcnn_load_predictor([predictorPath12 UTF8String]);
    assert(predictor12 != NULL);
    NSString* predictorPath13 = [[NSBundle mainBundle] pathForResource:@"jackjones_213427006" ofType:@"txt"];
    if (predictorPath13 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor13 = jpcnn_load_predictor([predictorPath13 UTF8String]);
    assert(predictor13 != NULL);
    
    NSString* predictorPath14 = [[NSBundle mainBundle] pathForResource:@"jackjones_212427006" ofType:@"txt"];
    if (predictorPath14 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor14 = jpcnn_load_predictor([predictorPath14 UTF8String]);
    assert(predictor14 != NULL);
    NSString* predictorPath15 = [[NSBundle mainBundle] pathForResource:@"jackjones_212408029" ofType:@"txt"];
    if (predictorPath15 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor15 = jpcnn_load_predictor([predictorPath15 UTF8String]);
    assert(predictor15 != NULL);
    
    NSString* predictorPath16 = [[NSBundle mainBundle] pathForResource:@"jackjones_212427021" ofType:@"txt"];
    if (predictorPath16 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
         assert(false);
    }
    
    predictor16 = jpcnn_load_predictor([predictorPath16 UTF8String]);
    assert(predictor16 != NULL);
    NSString* predictorPath17 = [[NSBundle mainBundle] pathForResource:@"jackjones_212427019" ofType:@"txt"];
    if (predictorPath17 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor17 = jpcnn_load_predictor([predictorPath17 UTF8String]);
    assert(predictor17 != NULL);
    NSString* predictorPath18 = [[NSBundle mainBundle] pathForResource:@"jackjones_212427017" ofType:@"txt"];
    if (predictorPath18 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor18 = jpcnn_load_predictor([predictorPath18 UTF8String]);
    assert(predictor18 != NULL);
    NSString* predictorPath19 = [[NSBundle mainBundle] pathForResource:@"selected_412427040" ofType:@"txt"];
    if (predictorPath19 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor19 = jpcnn_load_predictor([predictorPath19 UTF8String]);
    assert(predictor19 != NULL);
    NSString* predictorPath20 = [[NSBundle mainBundle] pathForResource:@"selected_412427014" ofType:@"txt"];
    if (predictorPath20 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor20 = jpcnn_load_predictor([predictorPath20 UTF8String]);
    assert(predictor20 != NULL);
    
    NSString* predictorPath21 = [[NSBundle mainBundle] pathForResource:@"selected_412427048" ofType:@"txt"];
    if (predictorPath21 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor21 = jpcnn_load_predictor([predictorPath21 UTF8String]);
    assert(predictor21 != NULL);
    
    NSString* predictorPath22 = [[NSBundle mainBundle] pathForResource:@"veromode_313427011" ofType:@"txt"];
    if (predictorPath22 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor22 = jpcnn_load_predictor([predictorPath22 UTF8String]);
    assert(predictor22 != NULL);
    
    NSString* predictorPath23 = [[NSBundle mainBundle] pathForResource:@"veromode_313427012" ofType:@"txt"];
    if (predictorPath23 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor23 = jpcnn_load_predictor([predictorPath23 UTF8String]);
    assert(predictor23 != NULL);
    
    NSString* predictorPath24 = [[NSBundle mainBundle] pathForResource:@"veromode_312427014" ofType:@"txt"];
    if (predictorPath24 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor24 = jpcnn_load_predictor([predictorPath24 UTF8String]);
    assert(predictor24 != NULL);
    
    NSString* predictorPath25 = [[NSBundle mainBundle] pathForResource:@"veromode_313327003" ofType:@"txt"];
    if (predictorPath25 == NULL) {
        fprintf(stderr, "Couldn't find the neural network predictor model file - did you add it as a resource to your application?\n");
        assert(false);
    }
    
    predictor25 = jpcnn_load_predictor([predictorPath25 UTF8String]);
    assert(predictor25 != NULL);
    
    
    
	[self setupAVCapture];
    [self scan];
    btnarray =[[NSMutableArray alloc] init];
    labelLayers = [[NSMutableArray alloc] init];
    oldPredictionValues = [[NSMutableDictionary alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [oldPredictionValues release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}
-(BOOL)shouldAutorotate
{
    return NO;
}
- (void)dealloc
{
	[self teardownAVCapture];
    [_freezebtn release];
	[super dealloc];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
		beginGestureScale = effectiveScale;
	}
	return YES;
}

- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    BOOL allTouchesAreOnThePreviewLayer = YES;
    	NSUInteger numTouches = [recognizer numberOfTouches], i;
    	for ( i = 0; i < numTouches; ++i ) {
    		CGPoint location = [recognizer locationOfTouch:i inView:previewView];
    		CGPoint convertedLocation = [previewLayer convertPoint:location fromLayer:previewLayer.superlayer];
    		if ( ! [previewLayer containsPoint:convertedLocation] ) {
    			allTouchesAreOnThePreviewLayer = NO;
    			break;
    		}
    	}
    
    	if ( allTouchesAreOnThePreviewLayer ) {
    		effectiveScale = beginGestureScale * recognizer.scale;
    		if (effectiveScale < 1.0)
    			effectiveScale = 1.0;
    		CGFloat maxScaleAndCropFactor = [[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
    		if (effectiveScale > maxScaleAndCropFactor)
    			effectiveScale = maxScaleAndCropFactor;
    		[CATransaction begin];
    		[CATransaction setAnimationDuration:.025];
    		[previewLayer setAffineTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
    		[CATransaction commit];
    	}

}
@end
