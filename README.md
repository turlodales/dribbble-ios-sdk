# DribbbleSDK

DribbbleSDK is easy-to-use iOS wrapper for [Dribbble SDK](http://developer.dribbble.com/). We're working hard to complete the full coverage of available methods and make this SDK the best Dribbble SDK for iOS. Have fun and stay tuned.


[![CI Status](http://img.shields.io/travis/agilie/dribbble-ios-sdk.svg?style=flat)](https://travis-ci.org/agilie/dribbble-ios-sdk)
[![Version](https://img.shields.io/cocoapods/v/dribbble-ios-sdk.svg?style=flat)](http://cocoadocs.org/docsets/dribbble-ios-sdk)
[![License](https://img.shields.io/cocoapods/l/dribbble-ios-sdk.svg?style=flat)](http://cocoadocs.org/docsets/dribbble-ios-sdk)
[![Platform](https://img.shields.io/cocoapods/p/dribbble-ios-sdk.svg?style=flat)](http://cocoadocs.org/docsets/dribbble-ios-sdk)

## Installation

Dribbble iOS SDK is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "DribbbleSDK"

To run the example project, clone the repo, and run `pod install` from the Demo directory first.

## Quick start

- All you need - setup your DRApiClient instance with your app Dribbble credentials
```obj-c
DRApiClientSettings *settings = [[DRApiClientSettings alloc] initWithBaseUrl:kBaseApiUrl
    oAuth2RedirectUrl:kIDMOAuth2RedirectURL
    oAuth2AuthorizationUrl:kIDMOAuth2AuthorizationURL
    oAuth2TokenUrl:kIDMOAuth2TokenURL
    clientId:kIDMOAuth2ClientId
    clientSecret:kIDMOAuth2ClientSecret
    clientAccessToken:kIDMOAuth2ClientAccessToken
    scopes:[NSSet setWithObjects:kDRPublicScope, kDRWriteScope, kDRUploadScope, nil]];
DRApiClient *apiClient = [[DRApiClient alloc] initWithSettings:settings];
```
Call the -authorizeWithWebView method to perform OAuth2 authorization. (You need UIWebView to display login web page)
```obj-c
[apiClient authorizeWithWebView:self.webView authHandler:^(NXOAuth2Account *account, NSError *error) {
    //here you can handle authorization results
}];
```

Authorization isn't required, you can use non-authorized access for some methods. In this case, API client uses default access token provided by Dribbble. You can get the app access token, client id and secret keys on your Dribbble app page, check out the next links: 

- Register your app on https://dribbble.com/account/applications/new

- Documentation: http://developer.dribbble.com/v1/

## API usage

Use DRApiClient class for all Dribbble stuff

- Native Dribbble authorization with authorizeWithWebView method
```obj-c
- (void)authorizeWithWebView:(UIWebView *)webView authHandler:(DROAuthHandler)authHandler;
```

- Get user info with loadUserInfoWithResponseHandler method
```obj-c
- (void)loadUserInfoWithResponseHandler:(DRResponseHandler)responseHandler;
```

- Get any user`s data with this methods using userID (account, likes, projects, teams, shots, followees)
```obj-c
- (void)loadAccountWithUser:(NSNumber *)userId responseHandler:(DRResponseHandler)responseHandler;
- (void)loadLikesWithUser:(NSNumber *)userId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)loadProjectsWithUser:(NSNumber *)userId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)loadTeamsWithUser:(NSNumber *)userId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)loadShotsWithUser:(NSNumber *)userId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)loadFolloweesWithUser:(NSNumber *)userId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
```

- Get your followee`s shots with loadFolloweesShotsWithParams method
```obj-c
- (void)loadFolloweesShotsWithParams:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
```

- You can upload, update or delete your shot with this methods
```obj-c
- (void)uploadShotWithParams:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)updateShot:(NSNumber *)shotId withParams:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)deleteShot:(NSNumber *)shotId responseHandler:(DRResponseHandler)responseHandler;
```

- Load shot/shots with params, from some category or just user`s shots with this methods
```obj-c
- (void)loadShotWith:(NSNumber *)shotId responseHandler:(DRResponseHandler)responseHandler;
- (void)loadShotsWithParams:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)loadShotsFromCategory:(DRShotCategory *)category atPage:(int)page responseHandler:(DRResponseHandler)responseHandler;
- (void)loadUserShots:(NSString *)url params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
```

- Get list rebounds for a shot with loadReboundsWithShot method
```obj-c
- (void)loadReboundsWithShot:(NSNumber *)shotId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
```

- You can like/unlike, chect is this shot liked, see who likes shot with this methods
```obj-c
- (void)likeWithShot:(NSNumber *)shotId responseHandler:(DRResponseHandler)responseHandler;
- (void)unlikeWithShot:(NSNumber *)shotId responseHandler:(DRResponseHandler)responseHandler;
- (void)checkLikeWithShot:(NSNumber *)shotId responseHandler:(DRResponseHandler)responseHandler;
- (void)loadLikesWithShot:(NSNumber *)shotId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
```

- Get comment/comments for shot, get likes with comments and check like with comment with this methods
```obj-c
- (void)loadCommentsWithShot:(NSNumber *)shotId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)loadCommentWith:(NSNumber *)commentId forShot:(NSString *)shotId responseHandler:(DRResponseHandler)responseHandler;
- (void)loadLikesWithComment:(NSNumber *)commentId forShot:(NSString *)shotId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)checkLikeWithComment:(NSNumber *)commentId forShot:(NSString *)shotId responseHandler:(DRResponseHandler)responseHandler;
```

- Get attachment/attachments for shot with loadAttachmentsWithShot and loadAttachmentWith:attachmentId methods
```obj-c
- (void)loadAttachmentsWithShot:(NSNumber *)shotId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)loadAttachmentWith:(NSNumber *)attachmentId forShot:(NSString *)shotId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
```

- Get projects for shot or exact project by projectID with this methods
```obj-c
- (void)loadProjectsWithShot:(NSNumber *)shotId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)loadProjectWith:(NSNumber *)projectId responseHandler:(DRResponseHandler)responseHandler;
```

- Get team members and all team shots with loadMembersWithTeam and loadShotsWithTeam methods
```obj-c
- (void)loadMembersWithTeam:(NSNumber *)teamId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
- (void)loadShotsWithTeam:(NSNumber *)teamId params:(NSDictionary *)params responseHandler:(DRResponseHandler)responseHandler;
```

- You can follow/unfollow user and check if you following user with this methods
```obj-c
- (void)followUserWith:(NSNumber *)userId responseHandler:(DRResponseHandler)responseHandler;
- (void)unFollowUserWith:(NSNumber *)userId responseHandler:(DRResponseHandler)responseHandler;
- (void)checkFollowingWithUser:(NSNumber *)userId responseHandler:(DRResponseHandler)responseHandler;
```

- Logout
```obj-c
- (void)logout;
```

## Requirements

iOS 7.0+

## Dependencies

API client is dependent on the next pods:

    'AFNetworking' for networking
    'JSONModel' for easy response-to-model translation
    'NXOAuth2Client' for OAuth2 authorization
    'BlocksKit' for general purposes

## Roadmap

Here is the features list we're planning to include in the future releases:
- Completed Dribbble API methods implementation.
- Request limit handling.
- Conditional requests support.

## Author

Agilie info@agilie.com

## License

DribbbleSDK is available under the MIT license. See the LICENSE file for more info.

