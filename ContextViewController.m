//
//  ContextViewController.m
//  Goguruz
//
//  Created by Arthur Evstifeev on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContextViewController.h"
#import "CoreDataHelper.h"

@implementation ContextViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _context = [[CoreDataHelper managedObjectContext] retain];
    }
    return self;
}

- (void)dealloc
{
    [_context release];
    [super dealloc];
}
@end
