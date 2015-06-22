//
//  DRImage.h
//  DribbbleRunner
//
//  Created by Vladimir Zgonik on 10.04.15.
//  Copyright (c) 2015 Agilie. All rights reserved.
//

#import "DRBaseModel.h"

@interface DRImage : DRBaseModel

@property (strong, nonatomic) NSString <Optional>*hidpi;
@property (strong, nonatomic) NSString <Optional>*normal;
@property (strong, nonatomic) NSString <Optional>*teaser;

@end
