//
//  NSDate+LocaleTime.m
//  Pods
//
//  Created by Arthur Evstifeev on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDate+LocaleTime.h"

@implementation NSDate (LocaleTime)

+ (NSDate*)localeTime {
    return [[self date] toLocaleTime];
}

- (NSDate*)toLocaleTime {
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:self];
    NSDate* localeT = [NSDate dateWithTimeInterval:seconds sinceDate:self];
    return localeT;
}

@end
