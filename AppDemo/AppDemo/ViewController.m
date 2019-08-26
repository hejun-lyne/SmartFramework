//
//  ViewController.m
//  AppDemo
//
//  Created by Li Hejun on 2019/8/26.
//  Copyright © 2019 Hejun. All rights reserved.
//

#import "ViewController.h"
#import "OneInterfaces.h"
#import "TwoInterfaces.h"
#import "Two/TwoComponent.h"
#import <smartframework/SFContext.h>

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableCell = [tableView dequeueReusableCellWithIdentifier:@"tableCell"];
    if (tableCell == nil) {
        tableCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"tableCell"];
    }
    switch (indexPath.row) {
        case 0:
            tableCell.textLabel.text = @"WeiboLogin";
            break;
        case 1:
            tableCell.textLabel.text = @"WeiboShare";
            break;
        case 2:
            tableCell.textLabel.text = @"AutoInjectComponent";
            break;
            
        default:
            break;
    }
    return tableCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            [SF_EXECUTOR(OneInterfaces) showWeiboLogin];
            break;
        case 1:
            [SF_EXECUTOR(OneInterfaces) shareWeiboText:@"Comment"];
            break;
        case 2:
            // 初始化TwoComponent, 这个实例会自动注入SFContext
            [TwoComponent.shared printIdentifier];
            // 通过SFContext获取到的实例和shared应该一致
            [SF_EXECUTOR(TwoInterfaces) printIdentifier];
            
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
