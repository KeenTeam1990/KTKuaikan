//
//  CartoonDetailViewController.m
//  kuaikanCartoon
//
//  Created by dengchen on 16/5/5.
//  Copyright © 2016年 name. All rights reserved.
//

#import "CartoonDetailViewController.h"
#import "CommentDetailViewController.h"
#import "WordsDetailViewController.h"
#import "AuthorInfoViewController.h"

#import "NetWorkManager.h"
#import "ProgressHUD.h"
#import "UserInfoManager.h"

#import <Masonry.h>
#import <UIImageView+WebCache.h>
#import <UITableView+FDTemplateLayoutCell.h>

#import "comicsModel.h"
#import "CommentsModel.h"
#import "CommonMacro.h"

#import "CommentSectionHeadView.h"
#import "FindHeaderSectionView.h"
#import "CartoonFlooterView.h"
#import "CartoonContentCell.h"
#import "authorInfoHeadView.h"
#import "CommentBottomView.h"
#import "CommentInfoCell.h"
#import "UIView+Extension.h"


@interface CartoonDetailViewController () <UITableViewDataSource,UITableViewDelegate,CartoonFlooterViewDelegate>

@property (nonatomic,strong) comicsModel *comicsMd;

@property (nonatomic,weak)   UILabel *titleLabel;

@property (nonatomic,weak)   UITableView *cartoonContentView;

@property (nonatomic,weak)   CommentBottomView *bottomView;

@property (nonatomic,weak)   UISlider *progress;

@property (nonatomic,strong) NSMutableArray *imageCellHeightCache;

@property (nonatomic,strong) NSArray *commentModels;

@property (nonatomic,strong) CartoonFlooterView *flooter;

@end


static const CGFloat imageCellHeight = 250.0f;

@implementation CartoonDetailViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setAutomaticallyAdjustsScrollViewInsets:YES];
 
    [self setupCartoonContentView];
    
    [self setupNavigationBar];
    
    [self setupCommentBottomView];
    
    [self setupProgress];
    
    [self requestData];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor whiteColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
     [self.bottomView resignFirstResponder];
     [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];

}

- (void)keyboardFrameChange:(NSNotification *)not {
    
    CGFloat end_Y = [not.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    
    CGFloat offset = SCREEN_HEIGHT - end_Y;
    
    self.bottomView.beginComment = offset > 0;
    
    [self.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-offset);
    }];
    
    [self hideOrShowProgressView:YES];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)requestData {
    
   NSString *url = [NSString stringWithFormat:@"http://api.kuaikanmanhua.com/v1/comics/%@?",self.cartoonId];
    
    weakself(self);
    
    [self hideNavBar:NO];
    [self.cartoonContentView setHidden:YES];
    
    self.comicsMd = nil;
    self.commentModels = nil;
    
   [comicsModel requestModelDataWithUrlString:url complish:^(id res) {
       
       if (res == nil) return ;
       
       CartoonDetailViewController *sself = weakSelf;
       
        sself.imageCellHeightCache = nil;
        sself.comicsMd = res;
        [sself updataUI];
       
        [sself hideOrShowProgressView:NO];
       
       
   } cachingPolicy:ModelDataCachingPolicyDefault hubInView:self.view];
    
    
}

- (void)updataUI {
    
    self.titleLabel.text = self.comicsMd.title;
    self.bottomView.recommend_count = self.comicsMd.comments_count.integerValue;
    self.progress.maximumValue = self.comicsMd.images.count - 1;
    self.progress.value = 0.0f;
    
    [self.cartoonContentView reloadData];
    [self.cartoonContentView layoutIfNeeded];
    [self.cartoonContentView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                         atScrollPosition:UITableViewScrollPositionNone animated:NO];
    [self.cartoonContentView setHidden:NO];
}

static CGFloat progressWidth = 150;

- (void)hideOrShowHeadBottomView:(BOOL)needhide
{
    if (self.navigationController.navigationBar.hidden == needhide) return;
    
    [self.view endEditing:needhide];
    
    self.statusBarHidden = needhide;
    
    [self.navigationController setNavigationBarHidden:needhide animated:YES];
    
    CGFloat offset = needhide ? bottomBarHeight : 0;
    
    [self.bottomView mas_updateConstraints:^(MASConstraintMaker *make) {    //隐藏底部视图
        make.bottom.equalTo(self.view).offset(offset);
    }];

    [UIView animateWithDuration:0.25 animations:^{
        [self.bottomView layoutIfNeeded];
    }];
    
}


- (void)hideOrShowProgressView:(BOOL)needhide {
    
    if (self.progress.hidden == needhide) return;
    
    if (needhide == NO) self.progress.hidden = needhide;
    
    CGFloat p_w = needhide ? 0 : progressWidth;
    
    [self.progress mas_updateConstraints:^(MASConstraintMaker *make) {      //隐藏进度条
        make.width.equalTo(@(p_w));
    }];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.progress layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
      if (needhide == YES) self.progress.hidden = needhide;
        
    }] ;
    
}

static bool needHide = false;

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!self.bottomView.beginComment) {
        needHide = !needHide;
        [self hideOrShowHeadBottomView:needHide];
        [self hideOrShowProgressView:needHide];
    }else {
        [self.bottomView resignFirstResponder];
        [self hideOrShowProgressView:NO];
    }
}



- (void)setupNavigationBar {
    
    UIBarButtonItem *collectedWorks = [[UIBarButtonItem alloc] initWithTitle:@"全集" style:UIBarButtonItemStylePlain target:self action:@selector(gotoCollectedWorksPage)];
    
    self.navigationItem.rightBarButtonItem = collectedWorks;
    
    [collectedWorks setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17],NSForegroundColorAttributeName:subjectColor}forState:UIControlStateNormal];
    
    [super setBackItemWithImage:@"ic_nav_back_normal_11x19_" pressImage:@"ic_nav_back_pressed_11x19_"];
    
    [self setupTitleView];
}

- (void)setupTitleView {
    
    UIView *textView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH * 0.8, 40)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:textView.frame];
    
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:18];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"漫画内容";
    
    [textView addSubview:label];
    
    self.titleLabel = label;
    
    self.navigationItem.titleView = textView;
    
}

#pragma mark CommentBottomView

- (void)setupCommentBottomView {
    
    CommentBottomView *cb = [CommentBottomView commentBottomView];
    
    cb.dataType = ComicsCommentDataType;
    cb.commentID = self.cartoonId;
    
    [self.view addSubview:cb];
    
    [cb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.equalTo(@(bottomBarHeight));
    }];
    
    self.bottomView = cb;

}

- (void)gotoCollectedWorksPage {
    
    WordsDetailViewController *wdc = [[WordsDetailViewController alloc] init];
    
    wdc.wordsID = self.comicsMd.topic.ID.stringValue;
    
    [self.navigationController pushViewController:wdc animated:YES];
}


#pragma mark 设置滑动条

- (void)setupProgress{
    
    //进度滑动条
    UISlider *progress = [[UISlider alloc] init];
    
    [self.view addSubview:progress];
    
    [progress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@30);
        make.centerY.equalTo(self.view);
        make.width.equalTo(@(progressWidth));
        make.centerX.equalTo(self.view.mas_right).offset(-20);
    }];
    
    //设置滑动条
    
    progress.minimumValue = 0;
    progress.maximumValue = 1;
    progress.value = 0;
    progress.continuous = NO;
    
    [progress setMaximumTrackImage:[UIImage imageNamed:@"progress_right"] forState:UIControlStateNormal];
    [progress setMinimumTrackImage:[UIImage imageNamed:@"progress_left"] forState:UIControlStateNormal];
    [progress setThumbImage:[UIImage imageNamed:@"progress_point"] forState:UIControlStateNormal];
    [progress setThumbImage:[UIImage imageNamed:@"progress_point"] forState:UIControlStateHighlighted];
    
    [progress addTarget:self action:@selector(sliderDragUp:) forControlEvents:UIControlEventValueChanged];

    progress.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    
    self.progress = progress;
}

- (void)sliderDragUp:(UISlider *)progress {
    [self.cartoonContentView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:progress.value inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
}



#pragma mark 设置tableview

static NSString * const CartoonContentCellIdentifier = @"CartoonContentCell";

- (void)setupCartoonContentView {
    
    UITableView *contentView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    
    [self.view addSubview:contentView];
    
    contentView.backgroundColor = [UIColor whiteColor];
    contentView.dataSource = self;
    contentView.delegate = self;
    contentView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    contentView.estimatedRowHeight = imageCellHeight;
    
    [contentView registerClass:[CartoonContentCell class] forCellReuseIdentifier:CartoonContentCellIdentifier];
    
    [contentView registerNib:[UINib nibWithNibName:@"CommentInfoCell" bundle:nil]  forCellReuseIdentifier:commentInfoCellName];
    
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
    }];
    
    self.cartoonContentView = contentView;
    
}


#pragma mark UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (section == 0) return authorInfoHeadViewHeight;
    if (section == 1) return CommentSectionHeadViewHeight;

    return 0;
}

- (void)gotoAuthorInfoPage {
    
    AuthorInfoViewController *AIVc = [AuthorInfoViewController new];
    
    AIVc.authorID = self.comicsMd.topic.user.ID.stringValue;
    
    [self.navigationController pushViewController:AIVc animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (section == 0) {
        
        authorInfoHeadView *head = [[authorInfoHeadView alloc] initWithFrame:self.view.bounds];
        
        head.model = self.comicsMd;
        
        [head addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gotoAuthorInfoPage)]];
        
        return head;
    }
    
    if (section == 1) {
        return [[CommentSectionHeadView alloc] initWithFrame:self.view.bounds];
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) return CartoonFlooterViewHeight;

    return 0;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        self.flooter.model = self.comicsMd;
        
        return self.flooter;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return self.comicsMd.images.count;
    }else if (section == 1) {
        return self.commentModels.count;
    }
    
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        CartoonContentCell *cell = [tableView dequeueReusableCellWithIdentifier:CartoonContentCellIdentifier];
        
        NSURL *imageUrl = [NSURL URLWithString:self.comicsMd.images[indexPath.row]];
        
        weakself(self);
            
        [cell.content sd_setImageWithURL:imageUrl placeholderImage:placeImage_comic
                                 options:SDWebImageHighPriority|SDWebImageRetryFailed
                               completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                   
            __strong CartoonDetailViewController *sself = weakSelf;
                                   
                if (sself == nil) {
                   return ;
                }
            
            /*有个别图片高度不为250,如果与250的高偏差过大的话,
             获取该图片实际高,更新高的缓存,刷新tableview*/
            
            CGFloat imageHeight = image.size.height * 0.5;
            
            CGFloat cacheHeight = [sself.imageCellHeightCache[indexPath.row] doubleValue];
            
            CGFloat offset = fabs(imageHeight - cacheHeight);
            
            if (offset > 8) {
                
                NSNumber *newHeight = [NSNumber numberWithDouble:imageHeight];
                
                [sself.imageCellHeightCache replaceObjectAtIndex:indexPath.row withObject:newHeight];
                
                [sself.cartoonContentView reloadData];
                
            }
            
        }];
        
        return cell;

    }
    
    if (indexPath.section == 1)
    {
        CommentInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:commentInfoCellName];
        
        cell.commentsModel = self.commentModels[indexPath.row];
        
        return cell;
    }
    
    return nil;
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        self.progress.value = indexPath.row;
    }
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 && self.comicsMd) {
        
        return [self.imageCellHeightCache[indexPath.row] doubleValue];
        
    }else if (indexPath.section == 1) {
        
        return [self.cartoonContentView fd_heightForCellWithIdentifier:commentInfoCellName cacheByIndexPath:indexPath configuration:^(id cell) {
          
            CommentInfoCell *cell1 = (CommentInfoCell *)cell;
            
            cell1.commentsModel = self.commentModels[indexPath.row];
            
        }];

    }

    return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if (section == 1 && self.commentModels.count < 1 && self.comicsMd != nil) {
        
        weakself(self);
        
        NSString *commentUrl = [NSString stringWithFormat:@"http://api.kuaikanmanhua.com/v1/comics/%@/hot_comments?",self.cartoonId];
        
        [CommentsModel requestModelDataWithUrlString:commentUrl complish:^(id result) {
            
            if (result == nil) return ;
            
            CartoonDetailViewController *sself = weakSelf;
            sself.commentModels = result;
            [sself.cartoonContentView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        } cachingPolicy:ModelDataCachingPolicyDefault hubInView:weakSelf.view];
    }
}
- (void)dealloc {
    
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
         needHide = targetContentOffset -> y;
        [self hideOrShowHeadBottomView:needHide];
}

#pragma mark CartoonFlooterViewDelegate

- (void)commentButtonAction {
    [CommentDetailViewController showInVc:self withDataRequstID:self.cartoonId WithDataType:ComicsCommentDataType];
}                       //开启评论

- (void)previousPage {
    self.cartoonId = self.comicsMd.previous_comic_id;
    [self requestData];
}                       //上一篇

- (void)nextPage {
    self.cartoonId = self.comicsMd.next_comic_id;
    [self requestData];
}                       //下一篇

- (void)showShareView {
    
}                       //显示分享视图

#pragma mark Lazy load

- (NSMutableArray *)imageCellHeightCache {
    if (!_imageCellHeightCache && self.comicsMd) {
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        
        for (NSInteger index = 0; index < self.comicsMd.images.count; index++) {
            [arr addObject:@(imageCellHeight)];
        }
        
        _imageCellHeightCache = arr;
    }
    return _imageCellHeightCache;
}

- (CartoonFlooterView *)flooter {
    if (!_flooter) {
        _flooter = [CartoonFlooterView makeCartoonFlooterView];
        _flooter.delegate = self;
    }
    return _flooter;
}


@end
