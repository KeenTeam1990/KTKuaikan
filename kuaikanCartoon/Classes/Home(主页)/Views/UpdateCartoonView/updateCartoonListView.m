//
//  updateCartoonListView.m
//  kuaikanCartoon
//
//  Created by dengchen on 16/5/3.
//  Copyright © 2016年 name. All rights reserved.
//

#import "updateCartoonListView.h"
#import "SummaryListItem.h"
#import "DateManager.h"

@interface updateCartoonListView ()<UICollectionViewDataSource>

@property (nonatomic,strong) UICollectionViewFlowLayout *flowLayout;

@property (nonatomic,strong) NSArray *requestUrlArray;

@end

@implementation updateCartoonListView

- (void)scrollToToday {
    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.requestUrlArray.count - 1 inSection:0]
                 atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame collectionViewLayout:self.flowLayout];
    if (self) {
        
        self.flowLayout.itemSize = self.bounds.size;
        [self setup];
    }
    return self;
}

- (void)setup {
    
    self.dataSource = self;
    self.pagingEnabled = YES;
    self.bounces = NO;
    
    [self registerClass:[SummaryListItem class] forCellWithReuseIdentifier:@"SummaryListItem"];
}

- (void)reloadData {
    [super reloadData];
    [self scrollToToday];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.requestUrlArray.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SummaryListItem *item = [collectionView dequeueReusableCellWithReuseIdentifier:@"SummaryListItem" forIndexPath:indexPath];
    
    if (self.requestUrlArray.count - 1 == indexPath.row) {
        
        NSCalendar *calender = [NSCalendar currentCalendar];
        
        NSInteger hour = [calender components:NSCalendarUnitHour fromDate:[NSDate date]].hour;
        
        item.hasNotBeenUpdated = hour < 6;
        
    }else {
        item.hasNotBeenUpdated = NO;
    }
    
    item.urlString = self.requestUrlArray[indexPath.item];
    
    return item;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.flowLayout.itemSize = self.bounds.size;
    
}


- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.minimumInteritemSpacing = 0;
        _flowLayout.minimumLineSpacing = 0;
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _flowLayout;
}

- (NSArray *)requestUrlArray {
    if (!_requestUrlArray) {
        
      DateManager *date = [DateManager share];
        
        NSString *formatUrl = @"http://api.kuaikanmanhua.com/v1/daily/comic_lists/%@";
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:7];

        for (NSInteger index = 1; index < 8; index++) {
            
            NSString *timeStamp = [date timeStampWithDate:[date dateByTodayAddingDays:index - 7]]; 
            NSString *newUrl = [NSString stringWithFormat:formatUrl,timeStamp];
            
            [array addObject:newUrl];
        }
        
        _requestUrlArray = [array copy];
        
    }
    return _requestUrlArray;
}
@end
