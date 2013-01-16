//
//  TTAlert.h
//  10tracks
//
//  Created by Arthur Evstifeev on 11/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AEAlert : NSObject

+ (void)composeAlertViewWithTitle:(NSString *)title 
                       andMessage:(NSString *)message;

@end
