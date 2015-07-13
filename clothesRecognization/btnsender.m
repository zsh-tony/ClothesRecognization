
//
//  btnsender.m
//  SavedModelExample
//
//  Created by zsh tony on 14-5-19.
//
//

#import "btnsender.h"

@implementation btnsender

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        if (_btndict==nil) {
            _btndict=[[NSMutableDictionary alloc]init];
        }
        tag1=@"1";
        tag2=@"2";
        tag3=@"3";
        tag4=@"4";
        tag5=@"5";
        tag6=@"6";
        tag7=@"7";
        tag8=@"8";
        tag9=@"9";
        tag10=@"10";
        tag11=@"11";
        tag12=@"12";
        tag13=@"13";
        tag14=@"14";
        tag15=@"15";
        tag16=@"16";
        tag17=@"17";
        tag18=@"18";
        tag19=@"19";
        tag20=@"20";
        tag21=@"21";
        tag22=@"22";
        tag23=@"23";
        tag24=@"24";
        tag25=@"25";
        
        text1=@"女装_basichouse_HMCA723A";
        text2=@"女装_basichouse_HMJP226C";
        text3=@"女装_only_113427003";
        text4=@"女装_only_113327005";
        text5=@"女装_only_113327021";
        text6=@"女装_only_113327003";
        text7=@"男装_zara_0706_326";
        text8=@"男装_zara_0706_319";
        text9=@"男装_zara_1608_303";
        text10=@"男装_zara_0693_329";
        text11=@"男装_zara_0706_304";
        text12=@"男装_zara_6096_451";
        text13=@"男装_jackjones_213427006";
        text14=@"男装_jackjones_212427006";
        text15=@"男装_jackjones_212408029";
        text16=@"男装_jackjones_212427021";
        text17=@"男装_jackjones_212427019";
        text18=@"男装_jackjones_212427017";
        text19=@"男装_selected_412427040";
        text20=@"男装_selected_412427014";
        text21=@"男装_selected_412427048";
        text22=@"女装_veromode_313427011";
        text23=@"女装_veromode_313427012";
        text24=@"女装_veromode_312427014";
        text25=@"女装_veromode_313327003";
        
        [_btndict setObject:tag1 forKey:text1];
        [_btndict setObject:tag2 forKey:text2];
        [_btndict setObject:tag3 forKey:text3];
        [_btndict setObject:tag4 forKey:text4];
        [_btndict setObject:tag5 forKey:text5];
        [_btndict setObject:tag6 forKey:text6];
        [_btndict setObject:tag7 forKey:text7];
        [_btndict setObject:tag8 forKey:text8];
        [_btndict setObject:tag9 forKey:text9];
        [_btndict setObject:tag10 forKey:text10];
        [_btndict setObject:tag11 forKey:text11];
        [_btndict setObject:tag12 forKey:text12];
        [_btndict setObject:tag13 forKey:text13];
        [_btndict setObject:tag14 forKey:text14];
        [_btndict setObject:tag15 forKey:text15];
        [_btndict setObject:tag16 forKey:text16];
        [_btndict setObject:tag17 forKey:text17];
        [_btndict setObject:tag18 forKey:text18];
        [_btndict setObject:tag19 forKey:text19];
        [_btndict setObject:tag20 forKey:text20];
        [_btndict setObject:tag21 forKey:text21];
        [_btndict setObject:tag22 forKey:text22];
        [_btndict setObject:tag23 forKey:text23];
        [_btndict setObject:tag24 forKey:text24];
        [_btndict setObject:tag25 forKey:text25];
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

@end
