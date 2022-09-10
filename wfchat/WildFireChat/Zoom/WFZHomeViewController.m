//
//  ViewController.m
//  WFZoom
//
//  Created by WF Chat on 2021/9/3.
//  Copyright © 2021年 WildFireChat. All rights reserved.
//

#import "WFZHomeViewController.h"
#import "WFZStartConferenceViewController.h"
#import "WFZOrderConferenceViewController.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCChatClient.h>
#import "QQLBXScanViewController.h"
#import "StyleDIY.h"
#import "WFCSettingTableViewController.h"
#import "WFZConferenceInfoViewController.h"
#import "AppService.h"

@interface WFZHomeViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UIView *topPanel;
@property(nonatomic, strong)UITableView *tableView;

@property(nonatomic, strong)UIButton *joinButton;
@property(nonatomic, strong)UIButton *startButton;
@property(nonatomic, strong)UIButton *orderButton;

@property(nonatomic, strong)NSString *privateConferenceId;


@property(nonatomic, strong)NSArray<WFZConferenceInfo *> *favConferences;

@property(nonatomic, strong)UIImageView *emptyImageView;
@property(nonatomic, strong)UILabel *emptyLabel;
@end

@implementation WFZHomeViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"会议";
    self.view.backgroundColor = [UIColor whiteColor];
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kCONFERENCE_DESTROYED object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        [ws reloadData];
    }];
    
    
    [self initTopPannel];
    [self initTableView];
    NSArray *arrays = [[NSUserDefaults standardUserDefaults] objectForKey:@"SAVED_CONFERENCE_LIST"];
    NSMutableArray *fcs = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in arrays) {
        [fcs addObject:[WFZConferenceInfo fromDictionary:dict]];
    }
    self.favConferences = fcs;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"scan"] style:UIBarButtonItemStyleDone target:self action:@selector(onScan:)];
}

- (void)initTopPannel {
    CGRect bounds = self.view.bounds;
    self.topPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 0)];
    [self.view addSubview:self.topPanel];
    
    CGFloat offset = kStatusBarAndNavigationBarHeight + 32;
    
    
    CGFloat btnSize = 80;
    CGFloat labelHeight = 30;
    if (@available(iOS 13, *)) {
        labelHeight = 0;
    }
    CGFloat padding = (bounds.size.width - 3*btnSize)/3;
    self.joinButton = [[UIButton alloc] initWithFrame:CGRectMake(padding/2, offset, btnSize, btnSize+labelHeight)];
    [self.joinButton setImage:[UIImage imageNamed:@"join_conference"] forState:UIControlStateNormal];
    [self.joinButton setTitle:@"加入会议" forState:UIControlStateNormal];
    [self layoutButtonText:self.joinButton];
    [self.joinButton addTarget:self action:@selector(onJoinBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    self.startButton = [[UIButton alloc] initWithFrame:CGRectMake(padding/2 + padding + btnSize, offset, btnSize, btnSize+labelHeight)];
    [self.startButton setImage:[UIImage imageNamed:@"start_conference"] forState:UIControlStateNormal];
    [self.startButton setTitle:@"发起会议" forState:UIControlStateNormal];
    [self layoutButtonText:self.startButton];
    [self.startButton addTarget:self action:@selector(onStartBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    self.orderButton = [[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width-btnSize-padding/2, offset, btnSize, btnSize+labelHeight)];
    [self.orderButton setImage:[UIImage imageNamed:@"order_conference"] forState:UIControlStateNormal];
    [self.orderButton setTitle:@"预定会议" forState:UIControlStateNormal];
    [self layoutButtonText:self.orderButton];
    [self.orderButton addTarget:self action:@selector(onOrderBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.topPanel addSubview:self.joinButton];
    [self.topPanel addSubview:self.startButton];
    [self.topPanel addSubview:self.orderButton];
    
    offset += btnSize;
    offset += labelHeight;
    
    offset += 30;
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, offset, bounds.size.width, 1)];
    line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.9];
    [self.topPanel addSubview:line];
    offset += 1;
    
    CGRect frame = self.topPanel.frame;
    frame.size.height = offset;
    self.topPanel.frame = frame;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)reloadData {
    __weak typeof(self)ws = self;
    [[AppService sharedAppService] getFavConferences:^(NSArray<WFZConferenceInfo *> * _Nonnull conferences) {
        ws.favConferences = conferences;
        NSMutableArray *arrays = [[NSMutableArray alloc] init];
        for (WFZConferenceInfo *info in conferences) {
            [arrays addObject:[info toDictionary]];
        }
        [[NSUserDefaults standardUserDefaults] setObject:arrays forKey:@"SAVED_CONFERENCE_LIST"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } error:^(int errorCode, NSString * _Nonnull message) {
        NSLog(@"error");
    }];
}

- (void)setFavConferences:(NSArray<WFZConferenceInfo *> *)favConferences {
    _favConferences = favConferences;
    [self showEmptyConference:favConferences.count == 0];
    [self.tableView reloadData];
}

- (void)showEmptyConference:(BOOL)empty {
    self.emptyLabel.hidden = !empty;
    self.emptyImageView.hidden = !empty;
}

- (void)layoutButtonText:(UIButton *)button {
//    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [button setTitleColor:HEXCOLOR(0x0195ff) forState:UIControlStateNormal];
    button.imageView.layer.masksToBounds = YES;
    button.imageView.layer.cornerRadius = 8.f;

    //top left buttom right
    button.titleEdgeInsets = UIEdgeInsetsMake(button.imageView.frame.size.height+6, -button.imageView.frame.size.width,
                                              0, 0);

    button.imageEdgeInsets = UIEdgeInsetsMake(0,
                                              button.titleLabel.bounds.size.width, button.titleLabel.bounds.size.height+6, 0);
}

- (void)onJoinBtn:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"请输入会议号及密码" preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入会议号";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入会议密码（如果没有密码，请忽略）";
    }];
        
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *conferenceId = alertController.textFields.firstObject.text;
        NSString *pwd = alertController.textFields[1].text;
        WFZConferenceInfoViewController *vc = [[WFZConferenceInfoViewController alloc] init];
        vc.conferenceId = conferenceId;
        vc.password = pwd;
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:nil];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)onStartBtn:(id)sender {
    WFZStartConferenceViewController *vc = [[WFZStartConferenceViewController alloc] init];
    vc.createResult = ^(WFZConferenceInfo * _Nonnull conferenceInfo) {
        WFZConferenceInfoViewController *vc = [[WFZConferenceInfoViewController alloc] init];
        vc.conferenceId = conferenceInfo.conferenceId;
        vc.password = conferenceInfo.password;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nav animated:YES completion:^{
                        
        }];
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onOrderBtn:(id)sender {
    WFZOrderConferenceViewController *vc = [[WFZOrderConferenceViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)initTableView {
    CGRect topFrame = self.topPanel.frame;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topFrame.origin.y + topFrame.size.height, topFrame.size.width, self.view.bounds.size.height - topFrame.origin.y - topFrame.size.height)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.view addSubview:self.tableView];
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2 - 100, self.view.bounds.size.height /2 + 60, 200, 20)];
        _emptyLabel.font = [UIFont systemFontOfSize:14];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.text = @"暂无会议";
        _emptyLabel.textColor = [UIColor grayColor];
        [self.view addSubview:_emptyLabel];
    }
    return _emptyLabel;
}

- (UIImageView *)emptyImageView {
    if (!_emptyImageView) {
        UIImage *img = [UIImage imageNamed:@"tea"];
        _emptyImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, img.size.width*2, img.size.height*2)];
        _emptyImageView.center = self.view.center;
        _emptyImageView.image = img;
        _emptyImageView.alpha = 0.5;
        [self.view addSubview:_emptyImageView];
    }
    return _emptyImageView;
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WFZConferenceInfo *info = self.favConferences[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = info.conferenceTitle;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [[NSDate alloc] init];
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:info.startTime];
    
    NSString *detail;
    if([now timeIntervalSince1970] > info.endTime) {
        detail = @"会议已结束";
    } else if([now timeIntervalSince1970] > info.startTime ) {
        detail = @"会议已开始，请尽快加入";
    } else {
        NSDateFormatter * formatter = [NSDateFormatter new];
        
        if([calendar component:NSCalendarUnitDay fromDate:startDate] == [calendar component:NSCalendarUnitDay fromDate:now]) {
            detail = @"今天";
        } else {
            formatter.dateFormat=@"MM月dd日";
            detail = [formatter stringFromDate:startDate];
        }
        
        formatter.dateFormat=@"HH：mm";
        detail = [detail stringByAppendingFormat:@" %@ 开始会议", [formatter stringFromDate:startDate]];
    }
    cell.detailTextLabel.text = detail;
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.favConferences.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFZConferenceInfo *info = self.favConferences[indexPath.row];
    WFZConferenceInfoViewController *vc = [[WFZConferenceInfoViewController alloc] init];
    vc.conferenceId = info.conferenceId;
    vc.password = info.password;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        WFZConferenceInfo *info = self.favConferences[indexPath.row];
        __weak typeof(self)ws = self;
        [[AppService sharedAppService] unfavConference:info.conferenceId success:^{
            [ws reloadData];
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
    }
}
@end
