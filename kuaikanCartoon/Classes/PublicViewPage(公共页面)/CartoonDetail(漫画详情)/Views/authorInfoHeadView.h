//
//  authorInfoHeadView.h
//  kuaikanCartoon
//
//  Created by dengchen on 16/5/5.
//  Copyright © 2016年 name. All rights reserved.
//

#import <UIKit/UIKit.h>
@class comicsModel;

static CGFloat authorInfoHeadViewHeight = 60;

@interface authorInfoHeadView : UIView

@property (nonatomic,strong) comicsModel *model;

@end
