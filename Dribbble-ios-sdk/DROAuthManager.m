//
//  DROAuthManager.m
//  DribbbleRunner
//
//  Created by Vladimir Zgonik on 31.03.15.
//  Copyright (c) 2015 Agilie. All rights reserved.
//

#import "DROAuthManager.h"
#import "DRApiClient.h"

@interface DROAuthManager () <UIWebViewDelegate>

@property (strong, nonatomic) id<NSObject> authCompletionObserver;
@property (strong, nonatomic) id<NSObject> authErrorObserver;

@end

@implementation DROAuthManager

#pragma mark - OAuth2 Logic

- (void)requestOAuth2Login:(UIWebView *)webView completionHandler:(DRCompletionHandler)completion failureHandler:(DRErrorHandler)errorHandler {
    webView.delegate = self;
    NXOAuth2AccountStore *accountStore = [NXOAuth2AccountStore sharedStore];
    [accountStore setClientID:kIDMOAuth2ClientId
                       secret:kIDMOAuth2ClientSecret
                        scope:[NSSet setWithObjects: @"public", @"write", nil]
             authorizationURL:[NSURL URLWithString:kIDMOAuth2AuthorizationURL]
                     tokenURL:[NSURL URLWithString:kIDMOAuth2TokenURL]
                  redirectURL:[NSURL URLWithString:kIDMOAuth2RedirectURL]
                keyChainGroup:kIDMOAccountType
               forAccountType:kIDMOAccountType];
    __weak typeof(self)weakSelf = self;
    [accountStore requestAccessToAccountWithType:kIDMOAccountType withPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kRedirectUrlDribbbleFormat, preparedURL.absoluteString, weakSelf.checkSumString]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
#warning TODO don't delete all cache, keep media

        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [webView loadRequest:request];
    }];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    if (self.authCompletionObserver) [notificationCenter removeObserver:self.authCompletionObserver];
    if (self.authErrorObserver) [notificationCenter removeObserver:self.authErrorObserver];
    
    self.authCompletionObserver = [notificationCenter addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification) {
        webView.alpha = 0.f;
        NXOAuth2Account *account = [[aNotification userInfo] objectForKey:NXOAuth2AccountStoreNewAccountUserInfoKey];
        NSLog(@"We have token in OAuthManager:%@", account.accessToken.accessToken);
        if (account.accessToken.accessToken.length > 0) {
            if (completion) completion([DRBaseModel modelWithData:account]);
        } else {
            if (errorHandler) errorHandler([DRBaseModel modelWithError:[NSError errorWithDomain:@"Invalid auth data" code:kHttpAuthErrorCode userInfo:nil]]);
        }
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.authCompletionObserver];
    }];
    self.authErrorObserver = [notificationCenter addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification) {
        NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
        if (errorHandler) {
            errorHandler([DRBaseModel modelWithError:error]);
        }
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.authErrorObserver];
    }];
}

#pragma mark - WebView Delegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (self.progressHUDShowBlock) {
        self.progressHUDShowBlock();
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.progressHUDDismissBlock) self.progressHUDDismissBlock();
    //if the UIWebView is showing our authorization URL, show the UIWebView control
    if ([webView.request.URL.absoluteString rangeOfString:kIDMOAuth2RedirectURL options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.webView.userInteractionEnabled = YES;
        NSDictionary *params = [self grabUrlParameters:webView.request.URL];
        if ([params objectForKey:@"code"]) {
            webView.alpha = 0.f;
            self.oauthUrlCode = [params objectForKey:@"code"];
            [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:kIDMOAccountType] enumerateObjectsUsingBlock:^(NXOAuth2Account * obj, NSUInteger idx, BOOL *stop) {
                [[NXOAuth2AccountStore sharedStore] removeAccount:obj];
            }];
            [[NXOAuth2AccountStore sharedStore] handleRedirectURL:webView.request.URL];
        } else {
            self.webView.userInteractionEnabled = NO;
        }
    } else if ([webView.request.URL.absoluteString rangeOfString:kUnacceptableWebViewUrl options:NSCaseInsensitiveSearch].location != NSNotFound) {
        if (self.dismissWebViewBlock) {
            self.dismissWebViewBlock();
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.progressHUDDismissBlock) self.progressHUDDismissBlock();
    [[UIAlertView alertWithError:error] show];
}

#pragma mark - Helpers

- (NSMutableDictionary *)grabUrlParameters:(NSURL *) url {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *tmpKey = [url query];
    for (NSString *param in [[url query] componentsSeparatedByString:@"="]) {
        if ([tmpKey rangeOfString:param].location == NSNotFound) {
            [params setValue:param forKey:tmpKey];
            tmpKey = nil;
        }
        tmpKey = param;
    }
    return params;
}

@end