//
//  LoginViewController.h
//  DribbbleSDKExample
//
//  Created by Dmitry Salnikov on 6/11/15.
//  Copyright (c) 2015 Agilie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DribbbleSDK.h"

typedef void(^AuthCompletionHandler)(BOOL success);

@interface LoginViewController : UIViewController

@property (strong, nonatomic) DRApiClient *apiClient;

@property (copy, nonatomic) AuthCompletionHandler authCompletionHandler;

@end
