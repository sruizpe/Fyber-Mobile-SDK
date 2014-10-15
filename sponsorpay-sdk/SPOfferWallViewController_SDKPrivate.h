//
//  SPOfferWallViewController_SDKPrivate.h
//  SponsorPaySDK
//
//  Created by tito on 13/08/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import "SPOfferWallViewController.h"
#import "SPCredentials.h"

typedef void (^SPViewControllerDisposalBlock)(void);

@interface SPOfferWallViewController (SDKPrivate)

@property (nonatomic, strong) SPCredentials *credentials;
@property (nonatomic, strong, readwrite) NSString *currencyName;
@property (nonatomic, copy) SPViewControllerDisposalBlock disposalBlock;

- (id)initWithCredentials:(SPCredentials *)credentials;

@end
