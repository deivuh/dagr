//
//  ViewController.h
//  Dagr
//
//  Created by David Hsieh on 3/25/14.
//  Copyright (c) 2014 David Hsieh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController <BLEDelegate>
{
    IBOutlet UISlider *rSlider, *gSlider, *bSlider, *tSlider;
    IBOutlet UIButton *connectBT;
    IBOutlet UILabel *rssiLB;
    IBOutlet UILabel *tempLB;
    IBOutlet UIButton *autoTempBT, *turnOffBT, *whiteBT;
    IBOutlet UIActivityIndicatorView *activityIndicator;
}

@property (strong, nonatomic) BLE *ble;

@end
