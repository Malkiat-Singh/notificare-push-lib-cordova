#import "NotificarePlugin.h"
#import "NotificareAppDelegateSurrogate.h"
#import "NotificarePushLib.h"

@implementation NSString (NotificareJSON)

- (NSString *)escapedString {
    NSString *escaped = [self stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    return escaped;
}

@end

@implementation NSDictionary (NotificareJSON)
- (NSString*)escapedJSONString {
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
    if (error != nil) {
        NSLog(@"NSDictionary escapedJSONString error: %@", [error localizedDescription]);
        return nil;
    } else {
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [json escapedString];
    }
}
@end

@implementation NSArray (NotificareJSON)
- (NSString*)escapedJSONString {
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
    if (error != nil) {
        NSLog(@"NSArray escapedJSONString error: %@", [error localizedDescription]);
        return nil;
    } else {
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [json escapedString];
    }
}
@end


@interface NotificarePlugin() {
    BOOL _handleNotification;
}
@end


@implementation NotificarePlugin

#define kPluginVersion @"1.1.2"

- (void)pluginInitialize {
	NSLog(@"Initializing Notificare Plugin version %@", kPluginVersion);
    [[NotificareAppDelegateSurrogate shared] setSurrogateDelegate:self];
    [[NotificarePushLib shared] launch];
    [[NotificarePushLib shared] setDelegate:self];
    [[NotificarePushLib shared] handleOptions:[[NotificareAppDelegateSurrogate shared] launchOptions]];
}

- (void)setHandleNotification:(CDVInvokedUrlCommand*)command {
    _handleNotification = [[command argumentAtIndex:0] boolValue];
}

- (void)enableNotifications:(CDVInvokedUrlCommand*)command {
    [[NotificarePushLib shared] registerForNotifications];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
}


- (void)enableLocationUpdates:(CDVInvokedUrlCommand*)command {
    [[NotificarePushLib shared] startLocationUpdates];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
}


- (void)disableNotifications:(CDVInvokedUrlCommand*)command {
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [[NotificarePushLib shared] unregisterDevice];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
}


- (void)disableLocationUpdates:(CDVInvokedUrlCommand*)command {
    [[[NotificarePushLib shared] locationManager] stopMonitoringSignificantLocationChanges];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
}


- (void)registerDevice:(CDVInvokedUrlCommand*)command {
    NSString *deviceID = [command argumentAtIndex:0];
    NSString *userID = [command argumentAtIndex:1];
    NSString *username = [command argumentAtIndex:2];
    if (username) {
        [[NotificarePushLib shared] registerDevice:[NSData dataFromHexadecimalString:deviceID] withUserID:userID withUsername:username completionHandler:^(NSDictionary *info) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        } errorHandler:^(NSError *error) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        }];
    } else if (userID) {
        [[NotificarePushLib shared] registerDevice:[NSData dataFromHexadecimalString:deviceID] withUserID:userID completionHandler:^(NSDictionary *info) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        } errorHandler:^(NSError *error) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        }];
    } else {
        [[NotificarePushLib shared] registerDevice:[NSData dataFromHexadecimalString:deviceID] completionHandler:^(NSDictionary *info) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        } errorHandler:^(NSError *error) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        }];
    }
}


- (void)getDeviceId:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[[NotificarePushLib shared] deviceToken]];
    [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
}


- (void)addDeviceTags:(CDVInvokedUrlCommand*)command {
    NSArray *tags = [command argumentAtIndex:0];
    if (tags) {
        [[NotificarePushLib shared] addTags:tags completionHandler:^(NSDictionary *info) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        } errorHandler:^(NSError *error) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        }];
    }
}


- (void)removeDeviceTag:(CDVInvokedUrlCommand*)command {
    NSString *tag = [command argumentAtIndex:0];
    if (tag) {
        [[NotificarePushLib shared] removeTag:tag completionHandler:^(NSDictionary *info) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        } errorHandler:^(NSError *error) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        }];
    }
}


- (void)clearDeviceTags:(CDVInvokedUrlCommand*)command {
    [[NotificarePushLib shared] clearTags:^(NSDictionary *info) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    } errorHandler:^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    }];
}


- (void)fetchDeviceTags:(CDVInvokedUrlCommand*)command {
    [[NotificarePushLib shared] getTags:^(NSDictionary *info) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[info objectForKey:@"tags"]];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    } errorHandler:^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    }];
}

- (void)createAccount:(CDVInvokedUrlCommand*)command {
    NSDictionary *params = @{@"email": [command argumentAtIndex:0], @"password": [command argumentAtIndex:1], @"userName": [command argumentAtIndex:2]};
    [[NotificarePushLib shared] createAccount:params completionHandler:^(NSDictionary *info) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    } errorHandler:^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    }];
}

- (void)validateUser:(CDVInvokedUrlCommand*)command {
    NSString *token = [command argumentAtIndex:0];
    [[NotificarePushLib shared] validateAccount:token completionHandler:^(NSDictionary *info) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    } errorHandler:^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    }];
}

- (void)sendPassword:(CDVInvokedUrlCommand*)command {
    NSDictionary *params = @{@"email": [command argumentAtIndex:0]};
    [[NotificarePushLib shared] sendPassword:params completionHandler:^(NSDictionary *info) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    } errorHandler:^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    }];
}

- (void)resetPassword:(CDVInvokedUrlCommand*)command {
    NSDictionary *params = @{@"password": [command argumentAtIndex:0]};
    NSString *token = [command argumentAtIndex:1];
    [[NotificarePushLib shared] resetPassword:params withToken:token completionHandler:^(NSDictionary *info) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    } errorHandler:^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    }];
}

- (void)changePassword:(CDVInvokedUrlCommand*)command {
    NSDictionary *params = @{@"password": [command argumentAtIndex:0]};
    [[NotificarePushLib shared] changePassword:params completionHandler:^(NSDictionary *info) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    } errorHandler:^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    }];
}

- (void)userLogin:(CDVInvokedUrlCommand*)command {
    NSString *username = [command argumentAtIndex:0];
    NSString *password = [command argumentAtIndex:1];
    if (username && password) {
        [[NotificarePushLib shared] loginWithUsername:username andPassword:password completionHandler:^(NSDictionary *info) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        } errorHandler:^(NSError *error) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
        }];
    }
}

- (void)userLogout:(CDVInvokedUrlCommand*)command {
    [[NotificarePushLib shared] logoutAccount];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
}

- (void)generateAccessToken:(CDVInvokedUrlCommand*)command {
    [[NotificarePushLib shared] generateAccessToken:^(NSDictionary *info) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[info objectForKey:@"user"]];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    } errorHandler:^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    }];
}

- (void)fetchUserDetails:(CDVInvokedUrlCommand*)command {
    [[NotificarePushLib shared] fetchAccountDetails:^(NSDictionary *info) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[info objectForKey:@"user"]];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    } errorHandler:^(NSError *error) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [[self commandDelegate] sendPluginResult:pluginResult callbackId:[command callbackId]];
    }];
}

- (void)openNotification:(CDVInvokedUrlCommand*)command {
    // NotificarePushLib needs the original payload from APNS
    [[NotificarePushLib shared] openNotification:@{@"notification": [command argumentAtIndex:0]}];
}

#pragma NotificarePushLibDelegate

- (void)notificarePushLib:(NotificarePushLib *)library onReady:(NSDictionary *)info {
    NSLog(@"Notificare ready");
}

- (void)notificarePushLib:(NotificarePushLib *)library didReceiveActivationToken:(NSString *)token {
    NSLog(@"received validation token %@", token);
    NSString *js = [NSString stringWithFormat:@"Notificare.validateUserTokenCallback('%@');", token];
    [[self webView] stringByEvaluatingJavaScriptFromString:js];
}

- (void)notificarePushLib:(NotificarePushLib *)library didReceiveResetPasswordToken:(NSString *)token {
    NSLog(@"received reset password token %@", token);
    NSString *js = [NSString stringWithFormat:@"Notificare.resetPasswordTokenCallback('%@');", token];
    [[self webView] stringByEvaluatingJavaScriptFromString:js];
}

#pragma UIApplicationDelegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *js = [NSString stringWithFormat:@"Notificare.registrationCallback(null, '%@');", [deviceToken hexadecimalString]];
    [[self webView] stringByEvaluatingJavaScriptFromString:js];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"Error registering for remote notifications: %@",error);
    NSString *js = [NSString stringWithFormat:@"Notificare.registrationCallback(new Error('%@'));", [[error localizedDescription] escapedString]];
    [[self webView] stringByEvaluatingJavaScriptFromString:js];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (_handleNotification && [userInfo objectForKey:@"id"]) {
        [[NotificarePushLib shared]getNotification:[userInfo objectForKey:@"id"] completionHandler:^(NSDictionary *info) {
            // Info is the full notification object in key "notification"
            NSDictionary *notification = [info objectForKey:@"notification"];
            NSString *js = [NSString stringWithFormat:@"Notificare.notificationCallback(%@);", [notification escapedJSONString]];
            [[self webView] stringByEvaluatingJavaScriptFromString:js];
        } errorHandler:^(NSError *error) {
            NSLog(@"Error fetching notification: %@",error);
        }];
    } else {
        [[NotificarePushLib shared] openNotification:userInfo];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [[NotificarePushLib shared]  handleOpenURL:url];
    return YES;
}


@end