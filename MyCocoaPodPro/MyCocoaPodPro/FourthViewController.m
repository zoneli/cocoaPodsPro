//
//  FourthViewController.m
//  MyCocoaPodPro
//
//  Created by lyz1 on 16/5/21.
//  Copyright © 2016年 lyz. All rights reserved.
//

#import "FourthViewController.h"

@interface FourthViewController ()

@end

@implementation FourthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *testbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    testbtn.frame = CGRectMake(100, 100, 30, 20);
    testbtn.backgroundColor = [UIColor redColor];
    [testbtn addTarget:self action:@selector(test) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:testbtn];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.title = @"我的";
    
}

- (void)test {
//    UIViewController *vc = [[UIViewController alloc]init];
//    vc.title = @"test";
//    vc.view.backgroundColor = [UIColor orangeColor];
//    [self.tabBarController.navigationController pushViewController:vc animated:YES];
    

///////////////////////////////////////////////////////////////////////////////////////////////////
//test RACSignal
//    RACSignal *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence.signal;
//    [letters subscribeNext:^(NSString *x) {
//        NSLog(@"%@", x);
//    }];

    __block unsigned subscriptions = 0;
    
    RACSignal *loggingSignal = [RACSignal createSignal:^ RACDisposable * (id<RACSubscriber> subscriber) {
        subscriptions++;
//        [subscriber sendCompleted];
        [subscriber sendNext:[NSString stringWithFormat:@"%d",subscriptions]];
        return nil;
    }];

    loggingSignal = [loggingSignal doNext:^(id x) {
        NSLog(@"donext");
    }];

    [loggingSignal subscribeNext:^(id x) {
        NSLog(@"subscribenetx=%@",x);
    }];
    
//    [[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        [subscriber sendNext:@1];
//        [subscriber sendCompleted];
//        return nil;
//    }] doNext:^(id x) {
//        // 执行[subscriber sendNext:@1];之前会调用这个Block
//        NSLog(@"doNext");;
//    }] doCompleted:^{
//        // 执行[subscriber sendCompleted];之前会调用这个Block
//        NSLog(@"doCompleted");;
//        
//    }] subscribeNext:^(id x) {
//        
//        NSLog(@"%@",x);
//    }];
    // 不会输出任何东西
//    loggingSignal = [loggingSignal doCompleted:^{
//        NSLog(@"about to complete subscription %u", subscriptions);
//    }];
//    
//    // 输出:
//    // about to complete subscription 1
//    // subscription 1
//    [loggingSignal subscribeCompleted:^{
//        NSLog(@"subscription %u", subscriptions);
//    }];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
