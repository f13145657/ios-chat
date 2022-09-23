//
//  WFCUConferenceCollectionViewLayout.m
//  WFChatUIKit
//
//  Created by Rain on 2022/9/21.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import "WFCUConferenceCollectionViewLayout.h"

@interface WFCUConferenceCollectionViewLayout ()
@property (strong, nonatomic) NSMutableArray * attrubutesArray;
@end

@implementation WFCUConferenceCollectionViewLayout
- (void)prepareLayout {
    [super prepareLayout];
    NSInteger count = [self.collectionView numberOfItemsInSection:0];

    CGRect rect = CGRectZero;
    rect.size = self.collectionView.bounds.size;
    
    const CGFloat width = rect.size.width/2;
    const CGFloat height = rect.size.height/2;
    
    self.attrubutesArray = [NSMutableArray array];
    for (int i = 0; i < count; i ++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes * attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

        CGRect frame;
        if(i == 0) {
            frame = rect;
        } else {
            int page = [self pageByRow:i];
            CGFloat startX = page * rect.size.width;
            int index = (i -1)%4;
            CGFloat x = startX;
            CGFloat y = 0;
            if(index == 1 || index == 3) {
                x += width;
            }
            if(index == 2 || index == 3) {
                y += height;
            }
            frame = CGRectMake(x , y, width, height);
        }
        attributes.frame = frame;
        
        
        [self.attrubutesArray addObject:attributes];
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.attrubutesArray[indexPath.row];
}

- (CGSize)collectionViewContentSize {
    UICollectionViewLayoutAttributes * attributes = [self.attrubutesArray lastObject];
    CGFloat width = attributes.frame.origin.x + attributes.frame.size.width;
    if((self.attrubutesArray.count-1)%4 == 1 || (self.attrubutesArray.count-1)%4 == 3) {
        width += self.collectionView.frame.size.width/2;
    }
    
    return CGSizeMake(width, self.collectionView.bounds.size.height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    return _attrubutesArray;
}

- (int)pageByRow:(int)row {
    if(row == 0){
        return 0;
    }
    return (row -1)/4 + 1;
}

- (NSMutableArray<NSIndexPath *> *)itemsInPage:(int)page {
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    if(page == 0) {
        [arr addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    } else {
        for (int i = (page-1)*4 +1; i < MIN(page*4, count); i++) {
            [arr addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
    
    return arr;
}

- (CGPoint)getOffsetOfItems:(NSArray<NSIndexPath *> *)items leftItems:(NSMutableArray<NSIndexPath *> *)leftItems rightItems:(NSMutableArray<NSIndexPath *> *)rightItems {
    int minRow = 0x1FFFFFFF;
    int maxRow = 0;
    for (NSIndexPath *indexPath in items) {
        if(indexPath.row < minRow) {
            minRow = (int)indexPath.row;
        }
        if(indexPath.row > maxRow) {
            maxRow = (int)indexPath.row;
        }
    }
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    int start;
    
    int pageRight = [self pageByRow:maxRow];
    int end = pageRight * width;
    
    int pageLeft = 0;
    if(minRow == 0) {
        start = 0;
    } else {
        pageLeft = [self pageByRow:minRow];
        start = pageLeft * width;
    }
    
    [leftItems addObjectsFromArray:[self itemsInPage:pageLeft]];
    [rightItems addObjectsFromArray:[self itemsInPage:pageRight]];
    
    return CGPointMake(start, end);
}
@end
