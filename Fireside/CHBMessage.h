//
//  CHBMessage.h
//  Fireside
//
//  Created by Ben Stovold on 01/09/2014.
//  Copyright (c) 2014 CocoaHeads Brisbane. All rights reserved.
//

@class RACSignal;

@interface CHBMessage : NSObject

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly, copy) NSString *text;

+ (void)sendMessage:(NSString *)messageText;

+ (RACSignal *)allMessages;

@end