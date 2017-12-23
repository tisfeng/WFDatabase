//
//  ViewController.m
//  WxfDatabase
//
//  Created by isfeng on 2017/12/17.
//  Copyright © 2017年 isfeng. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewHeight;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    self.view.layer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"You"].CGImage);
    self.view.backgroundColor = [UIColor orangeColor];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    _viewHeight.constant = 900;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
