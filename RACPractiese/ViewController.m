//
//  ViewController.m
//  RACPractiese
//
//  Created by xin on 17/2/2.
//  Copyright © 2017年 xin. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *commandTELTextField;
@property (weak, nonatomic) IBOutlet UITextField *commandVCTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (weak, nonatomic) IBOutlet UITextField *channelTextField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self addTapGesture];
    
    [self RACCommandOperaton];
    
    [self RACChannelOperation];
}

//点击获取验证码 倒数10秒以后可再次点击
- (void)RACCommandOperaton {
    RACSignal* (^countSignal)(NSNumber *count) = ^RACSignal* (NSNumber *count) {
        RACSignal *timerSignal = [RACSignal interval:1 onScheduler:RACScheduler.mainThreadScheduler];
        RACSignal *counterSignal = [[timerSignal scanWithStart:count reduce:^id(NSNumber *running, id next) {
            return @(running.integerValue - 1);
        }] takeUntilBlock:^BOOL(NSNumber *x) {
            return x.integerValue < 0;
        }];
        return [counterSignal startWith:count];
    };
    
    RACSignal *enableSignal = [self.commandTELTextField.rac_textSignal map:^id(NSString* value) {
        return @(value.length == 11);
    }];
    
    //按钮可不可用取决于 enableSignal 的值
    RACCommand *command = [[RACCommand alloc] initWithEnabled:enableSignal signalBlock:^RACSignal *(id input) {
        return countSignal(@10);
    }];
    
    self.sendButton.rac_command = command;
    
    RACSignal *countNumSignal = [[command.executionSignals switchToLatest] map:^id(NSNumber *value) {
        return [value stringValue];
    }];
    
    RACSignal *resetStringSignal = [[command.executing filter:^BOOL(NSNumber *value) {
        return !value.boolValue;
    }] mapReplace:@"点击获取验证码"];
    
    [self.sendButton rac_liftSelector:@selector(setTitle:forState:) withSignals:[RACSignal merge:@[countNumSignal, resetStringSignal]], [RACSignal return:@(UIControlStateNormal)], nil];
}

//每四位中间加一个横线，最多输入12位数字
- (void)RACChannelOperation {
    RACChannelTerminal *terminal = self.channelTextField.rac_newTextChannel;
    
    [[terminal map:^id(NSString *value) {
        const char *str = [value UTF8String];
        char newstr[15] = {0};
        int count = 0;
        for (int i = 0; i < value.length; i ++) {
            const char c = str[i];
            if (c <= '9' && c >= '0') {
                if (count == 4 || count == 9) {
                    newstr[count] = '-';
                    count ++;
                }
                newstr[count] = c;
                count ++;
            }
            if (count >= 14) {
                break;
            }
        }
        NSString *newValue = [NSString stringWithUTF8String:newstr];
        return newValue;
    }] subscribe:terminal];
}

- (void)addTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [[tap rac_gestureSignal] subscribeNext:^(id x) {
        [self.view endEditing:YES];
    }];
    [self.view addGestureRecognizer:tap];

}
@end
