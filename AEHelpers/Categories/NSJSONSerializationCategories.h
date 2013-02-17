//
//  NSString+NSJSONSerialization.h
//  AEHelpers
//
//  Created by Arthur Evstifeev on 15/02/13.
//
//

#import <Foundation/Foundation.h>

@interface NSString (NSJSONSerialization)

- (id)objectFromJSONString;

@end

@interface NSObject (NSJSONSerialization)

- (NSString *)JSONString;

@end
