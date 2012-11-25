//
//  JEViewController.h
//  JsonEngineTest
//
//  Created by Hidetoshi Mori on 12/11/25.
//  Copyright (c) 2012年 Hidetoshi Mori. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JEViewController : UIViewController {
    NSMutableArray *_records;
}

@end

@interface NSString (URLEncoding)
- (NSString *)urlencode;
- (NSString *)urldecode;
@end

