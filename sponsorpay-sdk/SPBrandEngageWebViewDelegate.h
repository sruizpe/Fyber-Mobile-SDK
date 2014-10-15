//
//  SPBrandEngageWebViewDelegate.h
//  SponsorPaySDK
//
//  Created by tito on 15/07/14.
//  Copyright (c) 2014 SponsorPay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPBrandEngageWebView;

@protocol SPBrandEngageWebViewDelegate<NSObject>

@required

// TODO: Missing documentation

/**
 *  <#Description#>
 *
 *  @param BEWebView      <#BEWebView description#>
 *  @param numberOfOffers <#numberOfOffers description#>
 */
- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView javascriptReportedOffers:(NSInteger)numberOfOffers;

/**
 *  <#Description#>
 *
 *  @param BEWebView <#BEWebView description#>
 */
- (void)brandEngageWebViewJavascriptOnStarted:(SPBrandEngageWebView *)BEWebView;

/**
 *  <#Description#>
 *
 *  @param BEWebView <#BEWebView description#>
 *  @param error     <#error description#>
 */
- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView didFailWithError:(NSError *)error;

/**
 *  <#Description#>
 *
 *  @param BEWebView <#BEWebView description#>
 */
- (void)brandEngageWebViewOnAborted:(SPBrandEngageWebView *)BEWebView;

/**
 *  <#Description#>
 *
 *  @param BEWebView <#BEWebView description#>
 *  @param url       <#url description#>
 */
- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView requestsToCloseFollowingOfferURL:(NSURL *)url;

/**
 *  <#Description#>
 *
 *  @param BEWebView   <#BEWebView description#>
 *  @param tpnName     <#tpnName description#>
 *  @param contextData <#contextData description#>
 */
- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView
   requestsValidationOfTPN:(NSString *)tpnName
               contextData:(NSDictionary *)contextData;

/**
 *  <#Description#>
 *
 *  @param BEWebView   <#BEWebView description#>
 *  @param tpnName     <#tpnName description#>
 *  @param contextData <#contextData description#>
 */
- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView
    requestsPlayVideoOfTPN:(NSString *)tpnName
               contextData:(NSDictionary *)contextData;

/**
 *  <#Description#>
 *
 *  @param BEWebView <#BEWebView description#>
 *  @param appId     <#appId description#>
 */
- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView requestsStoreWithAppId:(NSString *)appId affiliateToken:(NSString *)affiliateToken campaignToken:(NSString *)campaignToken;


/**
 *  <#Description#>
 *
 *  @param BEWebView       <#BEWebView description#>
 *  @param network         <#network description#>
 *  @param video           <#video description#>
 *  @param showAlert       <#showAlert description#>
 *  @param alertMessage    <#alertMessage description#>
 *  @param clickThroughURL <#clickThroughURL description#>
 */
- (void)brandEngageWebView:(SPBrandEngageWebView *)BEWebView
 playVideoFromLocalNetwork:(NSString *)network
                     video:(NSString *)video
                 showAlert:(BOOL)showAlert
              alertMessage:(NSString *)alertMessage
           clickThroughURL:(NSURL *)clickThroughURL;

@end