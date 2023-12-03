//
//  DarwinNotificationCenter.m
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-11.
//

#import "DarwinNotificationCenter.h"
#import <notify.h>

const int DarwinNotificationInvalidObserver = NOTIFY_TOKEN_INVALID;

@implementation DarwinNotificationCenter

+ (BOOL)isValidObserver:(int)observerToken
{
    return notify_is_valid_token(observerToken);
}

+ (void)postNotificationName:(const char *)name
{
//    OWSAssertDebug(name.isValid);
    notify_post(name);
}

+ (int)addObserverForName:(const char *)name
                    queue:(dispatch_queue_t)queue
               usingBlock:(notify_handler_t)block
{
//    OWSAssertDebug(name.isValid);

    int observerToken;
    notify_register_dispatch(name, &observerToken, queue, block);
    return observerToken;
}

+ (void)removeObserver:(int)observerToken
{
    if (![self isValidObserver:observerToken]) {
//        OWSFailDebug(@"Invalid observer token.");
        return;
    }

    notify_cancel(observerToken);
}

+ (void)setState:(uint64_t)state forObserver:(int)observerToken
{
    if (![self isValidObserver:observerToken]) {
//        OWSFailDebug(@"Invalid observer token.");
        return;
    }

    notify_set_state(observerToken, state);
}

+ (uint64_t)getStateForObserver:(int)observerToken
{
    if (![self isValidObserver:observerToken]) {
//        OWSFailDebug(@"Invalid observer token.");
        return 0;
    }

    uint64_t state;
    notify_get_state(observerToken, &state);
    return state;
}

@end
