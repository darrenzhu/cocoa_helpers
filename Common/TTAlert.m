//
//  TTAlert.m
//  10tracks
//
//  Created by Arthur Evstifeev on 11/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TTAlert.h"

@implementation TTAlert

+ (void)composeAlertViewWithTitle:(NSString *)title 
                       andMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                         message:message 
                                                        delegate:nil 
                                               cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                               otherButtonTitles:nil] autorelease];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
    });
}

@end
