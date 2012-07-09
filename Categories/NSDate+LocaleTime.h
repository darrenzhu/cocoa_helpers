//
//  NSDate+LocaleTime.h
//  Pods
//
//  Created by Arthur Evstifeev on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (LocaleTime)

+ (NSDate*)localeTime;
- (NSDate*)toLocaleTime;

@end
