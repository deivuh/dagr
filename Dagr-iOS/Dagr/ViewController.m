//
//  ViewController.m
//  Dagr
//
//  Created by David Hsieh on 3/25/14.
//  Copyright (c) 2014 David Hsieh. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Initialize BLE
    _ble = [[BLE alloc] init];
    [_ble controlSetup];
    _ble.delegate = self;
    
    rSlider.enabled = NO;
    gSlider.enabled = NO;
    gSlider.enabled = NO;
    bSlider.enabled = NO;
    tSlider.enabled = NO;
    autoTempBT.enabled = NO;
    turnOffBT.enabled = NO;
    whiteBT.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - BLE delegate

NSTimer *rssiTimer;

- (void)bleDidDisconnect
{
    NSLog(@"->Disconnected");
    
    [connectBT setTitle:@"Connect" forState:UIControlStateNormal];
    [activityIndicator stopAnimating];
    activityIndicator.hidden = YES;
    
    rSlider.enabled = NO;
    gSlider.enabled = NO;
    gSlider.enabled = NO;
    bSlider.enabled = NO;
    tSlider.enabled = NO;
    autoTempBT.enabled = NO;
    turnOffBT.enabled = NO;
    whiteBT.enabled = NO;
    
    rssiLB.text = @"---";
    
    [rssiTimer invalidate];
}

// When RSSI is changed, this will be called
-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
    rssiLB.text = rssi.stringValue;
}

-(void) readRSSITimer:(NSTimer *)timer
{
    [_ble readRSSI];
}

// When disconnected, this will be called
-(void) bleDidConnect
{
    NSLog(@"Connected");
    
    [activityIndicator stopAnimating];
    activityIndicator.hidden = YES;
    
    //Enable all controls once connected
    rSlider.enabled = YES;
    gSlider.enabled = YES;
    gSlider.enabled = YES;
    bSlider.enabled = YES;
    tSlider.enabled = YES;
    autoTempBT.enabled = YES;
    turnOffBT.enabled = YES;
    whiteBT.enabled = YES;
    
    // send reset
    UInt8 buf[] = {0x04, 0x00, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [_ble write:data];
    
    // Schedule to read RSSI every 1 sec.
    rssiTimer = [NSTimer scheduledTimerWithTimeInterval:(float)1.0 target:self selector:@selector(readRSSITimer:) userInfo:nil repeats:YES];
}

// When data is comming, this will be called
-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSLog(@"Length: %d", length);
    
    // parse data, all commands are in 3-byte
    for (int i = 0; i < length; i+=3)
    {
        NSLog(@"0x%02X, 0x%02X, 0x%02X", data[i], data[i+1], data[i+2]);
    }
}


#pragma mark - Actions

// Connect button will call to this
- (IBAction)scanBT:(id)sender
{
    if (_ble.activePeripheral)
        if(_ble.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[_ble CM] cancelPeripheralConnection:[_ble activePeripheral]];
            [connectBT setTitle:@"Connect" forState:UIControlStateNormal];
            return;
        }
    
    if (_ble.peripherals)
        _ble.peripherals = nil;
    
    [connectBT setEnabled:false];
    [_ble findBLEPeripherals:2];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
}

-(void) connectionTimer:(NSTimer *)timer
{
    [connectBT setEnabled:true];
    [connectBT setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    if (_ble.peripherals.count > 0)
    {
        [_ble connectPeripheral:[_ble.peripherals objectAtIndex:0]];
    }
    else
    {
        [connectBT setTitle:@"Connect" forState:UIControlStateNormal];
        [activityIndicator stopAnimating];
        activityIndicator.hidden = YES;
    }
}


//Send current RGB slider values
-(IBAction)sendColor:(id)sender
{
    UInt8 buf[4] = {0x02, 0x00, 0x00, 0x00};
    
    buf[1] = rSlider.value;
    buf[2] = gSlider.value;
    buf[3] = bSlider.value;
    
    NSData *data = [[NSData alloc] initWithBytes:buf length:4];
    [_ble write:data];
}

//Set white color
- (IBAction)setWhite:(id)sender {
    rSlider.value = 255;
    gSlider.value = 255;
    bSlider.value = 255;
    
    [self sendColor:sender];
}

//Set RGB values for current temperature value on slider
-(IBAction)setTemperature:(id)sender {
    
    int temperature = tSlider.value/ 100;
    
    if (temperature <= 66) {
        rSlider.value = 255;
    } else {
        rSlider.value = temperature - 60;
        rSlider.value = 329.698727446 * pow(rSlider.value, -0.1332047592);
    }
    
    if (temperature <= 66) {
        gSlider.value = temperature;
        gSlider.value = 99.4708025861 * log(gSlider.value) - 161.1195681661;
        
    } else {
        gSlider.value = temperature - 60;
        gSlider.value = 288.1221695283 * pow(gSlider.value, -0.0755148492);
    }
    
    if (temperature >= 66) {
        bSlider.value = 255;
    } else {
        if (temperature <= 19) {
            bSlider.value = 0;
        } else {
            bSlider.value = temperature - 10;
            bSlider.value = 138.5177312231 * log(bSlider.value) - 305.0447927307;
        }
    }
    
    [self sendColor:sender];
    
}

//Turn off LEDs
- (IBAction)turnOff:(id)sender {
    rSlider.value = 0;
    gSlider.value = 0;
    bSlider.value = 0;
    
    [self sendColor:sender];
}

//Update temperature label
- (IBAction)updateTemp:(id)sender {
    tempLB.text = [NSString stringWithFormat:@"%d K", (int)tSlider.value];
}

//Set temperature automatically based on time of the day
- (IBAction)autoSetTemp:(id)sender {
    
    
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    
    NSLog(@"%d:%d", hour, minute);
    
    if (hour < 6) {
        tSlider.value = 1500;
    } else if (hour < 8) {
        tSlider.value = 1500 + (minute * 20.34)*2/(hour-6);
    } else if (hour < 18) {
        tSlider.value = 4000;
    } else if (hour < 20) {
        tSlider.value = 4000 - (minute * 18.34) * 2/(20-hour);
    } else if (hour < 22) {
        tSlider.value = 4000 - (minute * 20.56) * 2/(22-hour);
    } else {
        tSlider.value = 1500;
    }
    
    [self updateTemp:sender];
    [self setTemperature:sender];
    [self sendColor:sender];
    
}



@end