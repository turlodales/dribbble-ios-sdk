//
//  DROAuthManager.m
//  DribbbleRunner
//
//  Created by Vladimir Zgonik on 31.03.15.
//  Copyright (c) 2015 Agilie. All rights reserved.
//

#import "DROAuthManager.h"
#import "DRApiClient.h"
#import "DRApiResponse.h"

@interface DROAuthManager ()

@property (strong, nonatomic) UIWebView *webView;

@property (strong, nonatomic) id<NSObject> authCompletionObserver;
@property (strong, nonatomic) id<NSObject> authErrorObserver;

@property (strong, nonatomic) NSString *redirectUrl;

@property (copy, nonatomic) DROAuthHandler authHandler;

@end

@implementation DROAuthManager

#pragma mark - OAuth2 Logic

- (void)authorizeWithWebView:(UIWebView *)webView settings:(DRApiClientSettings *)settings authHandler:(DROAuthHandler)authHandler {
    self.authHandler = authHandler;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    if (self.authCompletionObserver) [notificationCenter removeObserver:self.authCompletionObserver];
    if (self.authErrorObserver) [notificationCenter removeObserver:self.authErrorObserver];
    __weak typeof(self)weakSelf = self;
    
    self.authCompletionObserver = [notificationCenter addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification) {
        NXOAuth2Account *account = [[aNotification userInfo] objectForKey:NXOAuth2AccountStoreNewAccountUserInfoKey];
        logInteral(@"We have token in OAuthManager:%@", account.accessToken.accessToken);
        if (account.accessToken.accessToken) {
            [weakSelf finalizeAuthWithAccount:account error:nil];
        } else {
            [weakSelf finalizeAuthWithAccount:nil error:[NSError errorWithDomain:kInvalidAuthData code:kHttpAuthErrorCode userInfo:nil]];
        }
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.authCompletionObserver];
    }];
    self.authErrorObserver = [notificationCenter addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification) {
        NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
        [weakSelf finalizeAuthWithAccount:nil error:error];
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.authErrorObserver];
    }];

    [self requestAuthorizationWebView:webView withSettings:settings];
}

#pragma mark - WebView Delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([webView.request.URL.absoluteString rangeOfString:self.redirectUrl options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.webView.userInteractionEnabled = YES;
        NSDictionary *params = [self paramsFromUrl:webView.request.URL];
        if ([params objectForKey:@"code"]) {
            [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:kIDMOAccountType] enumerateObjectsUsingBlock:^(NXOAuth2Account * obj, NSUInteger idx, BOOL *stop) {
                [[NXOAuth2AccountStore sharedStore] removeAccount:obj];
            }];
            [[NXOAuth2AccountStore sharedStore] handleRedirectURL:webView.request.URL];
        } else {
            self.webView.userInteractionEnabled = NO;
        }
    } else if ([webView.request.URL.absoluteString rangeOfString:kUnacceptableWebViewUrl options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSError *error = [NSError errorWithDomain:kInvalidAuthData code:kHttpAuthErrorCode userInfo:nil];
        [self finalizeAuthWithAccount:nil error:error];
    }
}

- (BOOL)isUrlRedirectUrl:(NSURL *)url {
    NSURL *authUrl = [NSURL URLWithString:self.redirectUrl];
    return ([[authUrl host] isEqualToString:url.host] && [[authUrl scheme] isEqualToString:url.scheme]);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self isUrlRedirectUrl:request.URL]) {
        self.webView.userInteractionEnabled = YES;
        NSDictionary *params = [self paramsFromUrl:request.URL];
        if ([params objectForKey:@"code"]) {
            [[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:kIDMOAccountType] enumerateObjectsUsingBlock:^(NXOAuth2Account * obj, NSUInteger idx, BOOL *stop) {
                [[NXOAuth2AccountStore sharedStore] removeAccount:obj];
            }];
            [[NXOAuth2AccountStore sharedStore] handleRedirectURL:request.URL];
        } else {
            self.webView.userInteractionEnabled = NO;
        }
        return NO;
    }
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self finalizeAuthWithAccount:nil error:error];
}

#pragma mark - Helpers

- (void)finalizeAuthWithAccount:(NXOAuth2Account *)account error:(NSError *)error {
    if (self.authHandler) {
        self.authHandler(account, error);
        self.authHandler = nil;

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        if (self.authCompletionObserver) [notificationCenter removeObserver:self.authCompletionObserver];
        if (self.authErrorObserver) [notificationCenter removeObserver:self.authErrorObserver];
        self.authCompletionObserver = nil;
        self.authErrorObserver = nil;
    }
}

- (void)requestAuthorizationWebView:(UIWebView *)webView withSettings:(DRApiClientSettings *)settings {
    self.webView = webView;
    self.webView.delegate = self;
    
    NXOAuth2AccountStore *accountStore = [NXOAuth2AccountStore sharedStore];
    [accountStore setClientID:settings.clientId
                       secret:settings.clientSecret
                        scope:settings.scopes
             authorizationURL:[NSURL URLWithString:settings.oAuth2AuthorizationUrl]
                     tokenURL:[NSURL URLWithString:settings.oAuth2TokenUrl]
                  redirectURL:[NSURL URLWithString:settings.oAuth2RedirectUrl]
                keyChainGroup:kIDMOAccountType
               forAccountType:kIDMOAccountType];
    self.redirectUrl = settings.oAuth2RedirectUrl;
    
    [accountStore requestAccessToAccountWithType:kIDMOAccountType withPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:preparedURL];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [webView loadRequest:request];
    }];
}


- (NSMutableDictionary *)paramsFromUrl:(NSURL *)url {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *param in [[url query] componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if ([elts count] == 2) {
            [params setObject:[elts lastObject] forKey:[elts firstObject]];
        }
    }
    return params;
}
@end