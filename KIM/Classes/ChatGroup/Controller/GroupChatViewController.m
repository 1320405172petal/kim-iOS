//
//  GroupChatViewController.m
//  HUTLife
//
//  Created by Kakawater on 2018/4/24.
//  Copyright © 2018年 Kakawater. All rights reserved.
//

#import "GroupChatViewController.h"
#import "ChatToolBar.h"
#import "ChatMessage.h"
#import "ChatMessageCell.h"
#import "GroupMemberListViewController.h"
static NSString * const ChatMessageCellIdentifier = @"ChatMessageCell";

@interface GroupChatViewController ()<UITableViewDelegate,UITableViewDataSource,ChatToolBarDelegate,KIMGroupChatSessionDelegate>
@property(nonatomic,strong)KIMChatGroup * chatGroup;
@property(nonatomic,strong)UITableView *chatView;
@property(nonatomic,strong)UIRefreshControl *refreshControl;
@property(nonatomic,strong)ChatToolBar *toolBar;
@property(nonatomic,assign)BOOL isActiveViewController;
@property(nonatomic,strong)KIMChatGroupSession * chatGroupSession;
/**
 *@description 聊天消息列表
 */
@property(nonatomic,strong)NSMutableArray<KIMChatGroupMessage*> *chatGroupMessageList;
@end

@implementation GroupChatViewController
+(instancetype)groupChatViewController:(KIMChatGroup*)chatGroup
{
    GroupChatViewController * viewController = [[GroupChatViewController alloc] init];
    [viewController setChatGroup:chatGroup];
    return viewController;
}

-(NSMutableArray<KIMChatGroupMessage*> *)chatGroupMessageList
{
    if (self->_chatGroupMessageList) {
        return self->_chatGroupMessageList;
    }
    
    self->_chatGroupMessageList = [NSMutableArray<KIMChatGroupMessage*> array];
    
    return self->_chatGroupMessageList;
}

-(ChatToolBar*)toolBar
{
    if (self->_toolBar) {
        return self->_toolBar;
    }
    CGFloat toolBarHeight = 42;
    self->_toolBar = [[ChatToolBar alloc] initWithFrame:CGRectMake(0, [[self view] bounds].size.height-toolBarHeight, [[self view] bounds].size.width, toolBarHeight)];
    [self->_toolBar setDelegate:self];
    return self->_toolBar;
}

-(UITableView*)chatView
{
    if (self->_chatView) {
        return self->_chatView;
    }
    
    CGFloat chatViewWidth = [[self view] bounds].size.width;
    CGFloat chatViewHeight = [[self view] bounds].size.height - [[self toolBar] bounds].size.height;
    
    self->_chatView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, chatViewWidth, chatViewHeight) style:UITableViewStylePlain];
    
    [self->_chatView setDelegate:self];
    [self->_chatView setDataSource:self];
    [self->_chatView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    if (![[[self navigationController] navigationBar] isHidden]) {
        [self->_chatView setBounds:CGRectMake(0, -[[[self navigationController] navigationBar] bounds].size.height, chatViewWidth, chatViewHeight)];
    }
    
    //注册ChatMessageCell
    [self->_chatView registerClass:[ChatMessageCell class] forCellReuseIdentifier:ChatMessageCellIdentifier];
    
    //添加刷新控件
    self->_chatView.refreshControl = self.refreshControl;
    
    //为ChatView添加Tap手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatViewTaped)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.cancelsTouchesInView = YES;
    [self->_chatView addGestureRecognizer:tapGesture];
    
    [self->_chatView setBackgroundColor:[UIColor colorWithRed:227/255.0 green:230/255.0 blue:234/255.0 alpha:1]];
    
    return self->_chatView;
}

-(void)chatViewTaped
{
    [[self toolBar] resignFirstResponder];
}

-(UIRefreshControl*)refreshControl
{
    if (self->_refreshControl) {
        return self->_refreshControl;
    }
    
    self->_refreshControl = [[UIRefreshControl alloc] init];
    self->_refreshControl.tintColor = [UIColor grayColor];
    self->_refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"正在加载"];
    [self->_refreshControl addTarget:self action:@selector(refreshControlInvoked) forControlEvents:UIControlEventValueChanged];
    return self->_refreshControl;
}

-(void)refreshControlInvoked
{
    KIMChatGroupMessage * chatGroupMessage = [[self.chatGroupMessageList sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"messageId" ascending:YES]]] firstObject];
    if (!chatGroupMessage) {
        [self.refreshControl endRefreshing];
    }else{
        __weak GroupChatViewController * weakSelf = self;
        [self.chatGroupSession loadMessage:20 withMaxMessageId:chatGroupMessage.messageId completion:^(KIMChatGroupSession *chatGroupSession, NSArray<KIMChatGroupMessage *> *messageList) {
            [weakSelf.chatGroupMessageList addObjectsFromArray:messageList];
            //对消息按照时间顺序进行排序
            [weakSelf.chatGroupMessageList sortUsingComparator:^NSComparisonResult(KIMChatGroupMessage * message1, KIMChatGroupMessage * message2) {
                return [message1.timestamp compare:message2.timestamp];
            }];
            
            [weakSelf.refreshControl endRefreshing];
            [weakSelf.chatView reloadData];
            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:messageList.count inSection:0];
            [weakSelf.chatView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionTop animated:NO];
            [weakSelf.chatView setScrollEnabled:NO];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.0001 * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [weakSelf.chatView setScrollEnabled:YES];
            });

        }];
    }
}

-(void)chatToolBar:(ChatToolBar*)toolBar didUserInputText:(NSString*)text
{
    //发送消息
    KIMChatGroupMessage * message = [[self chatGroupSession] sendTextMessage:text];
    [toolBar clearTextInput];
    [[self chatGroupMessageList] addObject:message];
    [[self chatView] reloadData];
    [self chatViewScrollToBottom:YES];
}

-(void)chatToolBar:(ChatToolBar *)toolBar didToolButtonClicked:(UIButton *)toolButton
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //填充view
    [[self view] addSubview:[self chatView]];
    [[self view] addSubview:[self toolBar]];
    
    KIMClient * imClient = ((AppDelegate*)UIApplication.sharedApplication.delegate).imClient;
    KIMChatGroupModule * chatGroupModule = [imClient chatGroupModule];
    KIMChatGroupInfo * chatGroupInfo = [chatGroupModule retriveChatGroupInfoFromLocalCache:self.chatGroup];
    
    if ([[chatGroupInfo groupName] hasContent]) {
        [self.navigationItem setTitle:chatGroupInfo.groupName];
    }else{
        [self.navigationItem setTitle:chatGroupInfo.chatGroup.groupId];
    }
    
    //监听键盘事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChangedFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    //获取ChatSession并且设置Delegate
    self.chatGroupSession = [imClient.chatModule getChatGroupSession:self.chatGroup];
    self.chatGroupSession.delegate = self;
    
    //加载10条最新的历史消息
    __weak GroupChatViewController * weakSelf = self;
    [self.chatGroupSession loadLastedMessageWithMaxCount:20 completion:^(KIMChatGroupSession *chatGroupSession, NSArray<KIMChatGroupMessage *> *messageList) {
        if (!weakSelf) {
            return;
        }
        [weakSelf.chatGroupMessageList addObjectsFromArray:messageList];
        //对消息按照时间顺序进行排序
        [weakSelf.chatGroupMessageList sortUsingComparator:^NSComparisonResult(KIMChatGroupMessage * message1, KIMChatGroupMessage * message2) {
            return [message1.timestamp compare:message2.timestamp];
        }];
        [weakSelf.chatView reloadData];
        [weakSelf chatViewScrollToBottom:NO];
    }];
}

-(void)chatViewScrollToBottom:(BOOL)animated
{
    if ([[self chatGroupMessageList] count] > 0) {
        NSIndexPath *indexpath = [NSIndexPath indexPathForRow:self.chatGroupMessageList.count-1 inSection:0];
        [self.chatView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isActiveViewController = YES;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.isActiveViewController = NO;
}

//接收到一条消息
-(void)didChatGroupSessionReceivedMessage:(KIMChatGroupSession*)groupChatSession message:(KIMChatGroupMessage*)chatGroupMessage
{
    [[self chatGroupMessageList] addObject:chatGroupMessage];
    [self.chatGroupMessageList sortUsingComparator:^NSComparisonResult(KIMChatGroupMessage * message1, KIMChatGroupMessage * message2) {
        return [message1.timestamp compare:message2.timestamp];
    }];
    if (self.isActiveViewController) {
        [[self chatView] reloadData];
        [self chatViewScrollToBottom:YES];
    }
}

-(void)keyBoardWillChangedFrame:(NSNotification*)notification
{
    CGRect keyboardFrameEnd = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat translationY = keyboardFrameEnd.origin.y - CGRectGetMaxY([[self toolBar] frame]);
    
    CGPoint chatViewCenter = [[self chatView] center];
    chatViewCenter = CGPointMake(chatViewCenter.x, chatViewCenter.y + translationY);
    [[self chatView] setCenter:chatViewCenter];
    
    CGPoint toolBarCenter = [[self toolBar] center];
    toolBarCenter = CGPointMake(toolBarCenter.x, toolBarCenter.y + translationY);
    [[self toolBar] setCenter:toolBarCenter];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.chatGroupMessageList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 获取聊天消息
    KIMChatGroupMessage * message = [[self chatGroupMessageList] objectAtIndex:[indexPath row]];
    // 获取Cell
    ChatMessageCell * messageCell = [tableView dequeueReusableCellWithIdentifier:ChatMessageCellIdentifier forIndexPath:indexPath];
    [messageCell setBackgroundColor:[UIColor clearColor]];
    
    ChatMessage * messageModel = [[ChatMessage alloc] init];
    messageModel.type = ChatMessageType_TextMessage;
    messageModel.senderName = message.sender.account;
    messageModel.textContent = message.content;
    messageModel.timestamp = message.timestamp;
    
    [messageCell setModel:messageModel];
    
    KIMClient * imClient = ((AppDelegate*)UIApplication.sharedApplication.delegate).imClient;
    
    if ([message.sender isEqual:imClient.currentUser]) {
        [messageCell setStype:ChatMessageCellStyle_Sended];
    }else{
        [messageCell setStype:ChatMessageCellStyle_Received];
    }
    
    KIMRosterModule * rosterModule = imClient.rosterModule;
    KIMUserVCard * userVCard = [rosterModule retriveUserVCardFromLocalCache:message.sender];
    if (userVCard) {
        if ([[userVCard nickName] hasContent]) {
            [messageModel setSenderName:userVCard.nickName];
        }
        [messageModel setSenderAvatar:userVCard.avatar];
        [messageCell loadModelInfo];
    }
    return messageCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 获取聊天消息对象
    KIMChatGroupMessage *message = [[self chatGroupMessageList] objectAtIndex:[indexPath row]];
    
    ChatMessage * messageModel = [[ChatMessage alloc] init];
    messageModel.type = ChatMessageType_TextMessage;
    messageModel.senderName = message.sender.account;
    messageModel.textContent = message.content;
    messageModel.timestamp = message.timestamp;
    
    return [ChatMessageCell rowHeightWithtextMessage:messageModel andMaxWidth:self.chatView.bounds.size.width];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
