//
//  WordsDetailModel.m
//  kuaikanCartoon
//
//  Created by dengchen on 16/5/8.
//  Copyright © 2016年 name. All rights reserved.
//

#import "wordsDetailModel.h"
#import "CartonnWordsModel.h"

@implementation wordsDetailModel

+ (NSArray<NSString *> *)setupDataFieldsIsModelArray:(BOOL *)isModelArray {
    return @[@"data"];
}

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"comics":[CartonnWordsModel class]};
}

@end
