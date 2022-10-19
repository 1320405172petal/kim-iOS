//
//  ChatSessionCell.m
//  HUTLife
//
//  Created by Kakawater on 2018/12/27.
//  Copyright © 2018 Kakawater. All rights reserved.
//

#import "ChatSessionCell.h"

@interface ChatSessionCell ()
/**
 *@ddescription 徽章
 */
@property(nonatomic,strong)UIImageView *avatarView;
/**
 *@description 标题
 */
@property(nonatomic,strong)UILabel *titleLabel;
/**
 *@description 提示
 */
@property(nonatomic,strong)UILabel *promptLabel;
@property(nonatomic,strong)UILabel * badgeValueLabel;
@end

@implementation ChatSessionCell
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self addSubview:[self avatarView]];
        [self addSubview:[self titleLabel]];
        [self addSubview:[self promptLabel]];
        [self addSubview:[self badgeValueLabel]];
    }
    
    return self;
}

-(UIImageView*)avatarView
{
    if (self->_avatarView) {
        return self->_avatarView;
    }
    self->_avatarView = [UIImageView new];
    CGSize flagImageViewSize = CGSizeMake(40, 40);
    [self->_avatarView setBounds:CGRectMake(0, 0, flagImageViewSize.width, flagImageViewSize.height)];
    [self->_avatarView setImage:[UIImage imageNamed:@"normal_avatar"]];
    [[self->_avatarView layer]setCornerRadius:flagImageViewSize.width/2];
    [self->_avatarView setClipsToBounds:YES];
    return self->_avatarView;
}

-(UILabel*)titleLabel
{
    if (self->_titleLabel) {
        return self->_titleLabel;
    }
    
    self->_titleLabel = [UILabel new];
    return self->_titleLabel;
}

-(UILabel*)promptLabel
{
    if (self->_promptLabel) {
        return self->_promptLabel;
    }
    
    self->_promptLabel = [UILabel new];
    
    return self->_promptLabel;
}

-(UILabel*)badgeValueLabel
{
    if(self->_badgeValueLabel){
        return self->_badgeValueLabel;
    }
    
    self->_badgeValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [[self->_badgeValueLabel layer] setCornerRadius:self->_badgeValueLabel.bounds.size.width/2.0];
    [self->_badgeValueLabel setClipsToBounds:YES];
    [self->_badgeValueLabel setBackgroundColor:[UIColor redColor]];
    [self->_badgeValueLabel setTextColor:[UIColor whiteColor]];
    [self->_badgeValueLabel setTextAlignment:NSTextAlignmentCenter];
    return self->_badgeValueLabel;
}

-(void)setModel:(ChatSessionMessageModel *)model
{
    self->_model = model;
    
    if([model.nickName hasContent]){
        self.titleLabel.text = model.nickName;
    }else{
        self.titleLabel.text = model.peerAccount;
    }
    if(model.avatar){
        self.avatarView.image = [UIImage imageWithData:model.avatar];
    }
    self.promptLabel.text = model.content;
    
    if (model.unReadCount) {
        [[self badgeValueLabel] setHidden:NO];
        [[self badgeValueLabel] setText:[NSString stringWithFormat:@"%ld",model.unReadCount]];
    }else{
        [[self badgeValueLabel] setHidden:YES];
    }
    
    [self setNeedsLayout];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat interval = 10;
    
    CGSize contentSize = [self bounds].size;
    
    //布局flagImageView
    CGSize avatarViewSize = [[self avatarView] bounds].size;
    [[self avatarView] setCenter:CGPointMake(avatarViewSize.width/2 + interval, contentSize.height/2)];
    
    //布局badgeLabel
    CGSize badgeLabelSize = [[self badgeValueLabel] bounds].size;
    [[self badgeValueLabel] setCenter:CGPointMake(contentSize.width-(interval + badgeLabelSize.width/2), contentSize.height/2)];
    
    //布局flageLabel
    [[self titleLabel] sizeToFit];
    CGSize titleLaelSize = [[self titleLabel] bounds].size;
    CGFloat flagLabelMarginTop = interval * 1.5;
    CGFloat flagLabelMarginLeft = CGRectGetMaxX([[self avatarView] frame]) + interval;
    [[self titleLabel] setFrame:CGRectMake(flagLabelMarginLeft, flagLabelMarginTop, titleLaelSize.width, titleLaelSize.height)];
    
    //布局promptLael
    [[self promptLabel] sizeToFit];
    CGSize promptLabelSize = [[self promptLabel] bounds].size;
    CGFloat promptLabelMarginLeft = CGRectGetMaxX([[self avatarView] frame]) + interval;
    CGFloat promptLabelMarginTop = CGRectGetMaxY([[self titleLabel] frame]) + interval/2;
    [[self promptLabel] setFrame:CGRectMake(promptLabelMarginLeft, promptLabelMarginTop, promptLabelSize.width, promptLabelSize.height)];
    
}


@end
