//
//  CHBMessage.m
//  Fireside
//
//  Created by Ben Stovold on 01/09/2014.
//  Copyright (c) 2014 CocoaHeads Brisbane. All rights reserved.
//

#import "CHBMessage.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Firebase/Firebase.h>

@interface CHBMessage ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *text;

@end

@implementation CHBMessage

+ (Firebase *)firebaseRef
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Use a serial queue to preserve Firebase's guarantees around the sequence in which observer blocks are fired.
        // See https://www.firebase.com/docs/ios/guide/retrieving-data.html#section-guarantees
        [Firebase setDispatchQueue:dispatch_queue_create("org.cocoaheadsbne.queue.firebase", DISPATCH_QUEUE_SERIAL)];
    });
    
    return [[Firebase alloc] initWithUrl:@"https://cocoaheads.firebaseio.com/"];
}

+ (void)sendMessage:(NSString *)messageText
{
    Firebase *newMessageRef = [self.firebaseRef childByAutoId];
    [newMessageRef setValue:@{@"text":messageText}];
    
}

+ (RACSignal *)allMessages
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        Firebase *allMessagesRef = self.firebaseRef;
        FirebaseHandle handle = [allMessagesRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            CHBMessage *message = [[CHBMessage alloc] initWithIdentifier:snapshot.name messageText:snapshot.value[@"text"]];
            [subscriber sendNext:message];
        }];
        return [RACDisposable disposableWithBlock:^{
            [allMessagesRef removeObserverWithHandle:handle];
        }];
    }];
}

#pragma mark - Designated Initializer

- (instancetype)initWithIdentifier:(NSString *)identifier messageText:(NSString *)text
{
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _text = [text copy];
    }
    return self;
}

#pragma mark - NSObject

- (NSUInteger)hash
{
    return self.identifier.hash ^ self.text.hash;
}

- (BOOL)isEqual:(id)obj
{
    if (![obj isKindOfClass:[CHBMessage class]]) return NO;
    
    CHBMessage *other = (CHBMessage *)obj;
    
    BOOL identifierIsEqual = self.identifier == other.identifier || [self.identifier isEqualToString:other.identifier];
    BOOL textIsEqual = self.text == other.text || [self.text isEqualToString:other.text];
    return identifierIsEqual && textIsEqual;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
