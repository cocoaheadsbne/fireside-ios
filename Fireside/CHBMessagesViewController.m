//
//  CHBViewController.m
//  Fireside
//
//  Created by Ben Stovold on 01/09/2014.
//  Copyright (c) 2014 CocoaHeads Brisbane. All rights reserved.
//

#import "CHBMessagesViewController.h"

#import "CHBMessage.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

#import <PHFComposeBarView/PHFComposeBarView.h>

@interface CHBMessagesViewController () <UITableViewDataSource, UITableViewDelegate, PHFComposeBarViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet PHFComposeBarView *composeBarView;

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, readonly) NSIndexPath *lastIndexPath;

@property (nonatomic, strong) RACDisposable *subscriber;


@end

@implementation CHBMessagesViewController

#pragma mark - The Juicy Stuff

- (void)dealloc
{
    [_subscriber dispose];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.messages = [NSMutableArray new];

    @weakify(self);
    self.subscriber = [[[CHBMessage allMessages] deliverOn:RACScheduler.mainThreadScheduler] subscribeNext:^(CHBMessage *message) {
        @strongify(self);
        [self.messages addObject:message];
        [self.tableView insertRowsAtIndexPaths:@[self.lastIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView scrollToRowAtIndexPath:self.lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }];
}

- (void)broadcastMessage:(NSString *)message
{
    [CHBMessage sendMessage:message];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    CHBMessage *message = self.messages[indexPath.row];
    cell.textLabel.text = message.text;
    
    return cell;
}

#pragma mark - The Boring Stuff

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.composeBarView.maxCharCount = 32;
    self.composeBarView.placeholder = NSLocalizedString(@"Message", nil);
    self.composeBarView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillToggle:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillToggle:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [super viewWillDisappear:animated];
}

- (NSIndexPath *)lastIndexPath
{
    return [NSIndexPath indexPathForRow:MAX(self.messages.count - 1, 0) inSection:0];
}


- (void)composeBarViewDidPressButton:(PHFComposeBarView *)composeBarView
{
    if (composeBarView.text.length > composeBarView.maxCharCount)
    {
        return;
    }
    
    [self broadcastMessage:composeBarView.text];
    [composeBarView setText:@"" animated:YES];
    [composeBarView resignFirstResponder];
}

- (void)keyboardWillToggle:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];

    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGRect composeBarViewFrame = self.composeBarView.frame;
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.height = composeBarViewFrame.origin.y = CGRectGetMinY(keyboardFrame) - CGRectGetHeight(self.composeBarView.bounds);
    self.composeBarView.frame = composeBarViewFrame;
    self.tableView.frame = tableViewFrame;
    
    if (self.messages.count > 0) [self.tableView scrollToRowAtIndexPath:self.lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    
    [UIView commitAnimations];
}


@end
