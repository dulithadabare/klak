//
//  DarwinNotificationCenter.h
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-11.
//

#ifndef DarwinNotificationCenter_h
#define DarwinNotificationCenter_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DarwinNotificationName;

extern const int DarwinNotificationInvalidObserver;

@interface DarwinNotificationCenter : NSObject

/// Determines if an observer token is valid for a current registration.
/// Negative integers are never valid. A positive or zero value is valid
/// if the current process has a registration associated with the given value.
/// @param observerToken The token returned by `addObserverForName:`
+ (BOOL)isValidObserver:(int)observerToken;

/// Post a darwin notification that can be listened for from other processes.
/// @param name The name of the notification to post.
+ (void)postNotificationName:(const char *)name;

/// Add an observer for a darwin notification of the given name.
/// @param name The name of the notification to listen for.
/// @param queue The queue to callback on.
/// @param block The block to callback. Includes the observer token as an input parameter to allow
/// removing the observer after receipt.
/// @return An `int` observer token that can be used to remove this observer.
+ (int)addObserverForName:(const char *)name queue:(dispatch_queue_t)queue usingBlock:(void (^)(int))block;

/// Stops listening for notifications registered by the given observer token.
/// @param observerToken The token returned by `addObserverForName:` for the notification you want to stop listening
/// for.
+ (void)removeObserver:(int)observerToken;

/// Sets the state value for a given observer. This value can be set and read from
/// any process listening for this notification. Note: `setState:` and `getState`
/// are vulnerable to races.
/// @param state The `uint64_t` state you wish to share with another process.
/// @param observerToken The token returned by `addObserverForName:` for the notification you want to set state for.
+ (void)setState:(uint64_t)state forObserver:(int)observerToken;

/// Retrieves the state for a given observer. This value can be set and read from
/// any process listening for this notification. Note: `setState:` and `getState`
/// are vulnerable to races.
/// @param observerToken The token returned by `addObserverForName:` for the notification you want to get state for.
+ (uint64_t)getStateForObserver:(int)observerToken;

@end

NS_ASSUME_NONNULL_END


#endif /* DarwinNotificationCenter_h */
