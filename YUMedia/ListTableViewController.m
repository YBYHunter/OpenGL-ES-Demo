//
//  ListTableViewController.m
//  YUMedia
//
//  Created by yuboyang02 on 2020/6/19.
//  Copyright © 2020 yuboyang02. All rights reserved.
//

#import "ListTableViewController.h"
#import "ListsTableViewCell.h"
#import "ViewController.h"
#import "ShaderViewController.h"
#import "BoxViewController.h"

@interface ListTableViewController ()

@property (nonatomic, strong) NSMutableArray *dataLists;

@end

@implementation ListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OpenGL ES Demo";
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[ListsTableViewCell class] forCellReuseIdentifier:@"ListsTableViewCell"];
    UIView *headView = [[UIView alloc] init];
    headView.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
    self.tableView.tableHeaderView = headView;
    
    [self.dataLists addObject:@"一：纹理"];
    [self.dataLists addObject:@"二：着色器"];
    [self.dataLists addObject:@"三：深度测试"];
    [self.dataLists addObject:@"三：三维模型"];
    [self.tableView reloadData];
}

#pragma mark - Private Method

- (void)jumpToVC:(NSString *)message {
    NSInteger num = [self.dataLists indexOfObject:message];
    UIViewController *vc = nil;
    switch (num) {
        case 0:
            vc = [[ViewController alloc] init];
            break;
        case 1:
            vc = [[ShaderViewController alloc] init];
            break;
        case 2:
            vc = [[BoxViewController alloc] init];
            break;
        case 3:
//            vc = [[ alloc] init];
            break;
            
        default:
            break;
    }
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataLists.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListsTableViewCell" forIndexPath:indexPath];
    NSString *message = self.dataLists[indexPath.row];
    cell.textLabel.text = message;
    
    return cell;
}

#pragma mark - getter

- (NSMutableArray *)dataLists {
    if (_dataLists == nil) {
        _dataLists = [[NSMutableArray alloc] init];
    }
    return _dataLists;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self jumpToVC:self.dataLists[indexPath.row]];
}



@end
