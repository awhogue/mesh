//
//  MeshViewController.m
//  Mesh
//
//  Created by ahogue on 10/22/13.
//  Copyright (c) 2013 ahogue. All rights reserved.
//

#import "MeshViewController.h"

static NSString * const kBeaconCellIdentifier = @"BeaconCell";
static NSString * const kUUID = @"0D5067C7-E8AD-41D2-A6DE-6C1325936DA0";
static NSString * const kIdentifier = @"MeshIdentifier";


@interface MeshViewController ()

@property (weak, nonatomic) IBOutlet UITextField *registerTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
- (IBAction)registerAction:(id)sender;

@property (nonatomic, strong) NSArray *detectedBeacons;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSString *registeredName;
@property (nonatomic, weak) NSNumber *beaconMajorID;
@property (nonatomic, weak) NSNumber *beaconMinorID;

@end

@implementation MeshViewController

- (void)createBeaconRegion
{
    if (self.beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                                                major:[self.beaconMajorID unsignedIntegerValue]
                                                                minor:[self.beaconMinorID unsignedIntegerValue]
                                                           identifier:kIdentifier];
}

- (void)startRanging
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.detectedBeacons = [NSArray array];
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"Couldn't turn on ranging: Ranging is not available.");
        return;
    }
    if (self.locationManager.rangedRegions.count > 0) {
        NSLog(@"Didn't turn on ranging: Ranging already on.");
        return;
    }
    
    [self createBeaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"Ranging turned on for region: %@.", self.beaconRegion);
}

- (void)setupMajorMinorIdentifiers
{
    NSUUID *idForVendor;
#if TARGET_IPHONE_SIMULATOR
    idForVendor = [[NSUUID alloc] initWithUUIDString:@"8DC75C8A-835A-40AB-BD5C-09E86B05924D"];
#else
    idForVendor = [UIDevice currentDevice].identifierForVendor;
#endif
    unsigned majorID = 0;
    unsigned minorID = 0;
    NSString *idForVendorString = [idForVendor UUIDString];
    NSLog(@"%@", idForVendorString);
    NSScanner *majorScanner = [NSScanner scannerWithString:[idForVendorString substringToIndex:8]];
    [majorScanner scanHexInt:&majorID];
    NSScanner *minorScanner = [NSScanner scannerWithString:[idForVendorString substringFromIndex:24]];
    [minorScanner scanHexInt:&minorID];
    self.beaconMajorID = [NSNumber numberWithUnsignedInt:majorID];
    self.beaconMinorID = [NSNumber numberWithUnsignedInt:minorID];
    NSLog(@"Got major,minor IDs: %@,%@", self.beaconMajorID, self.beaconMinorID);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupMajorMinorIdentifiers];
    [self startRanging];
    self.registerTextField.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// TODO(ahogue): Replace this with a call to the server to pull a username for the beacon.
- (NSString *)detailsStringForBeacon:(CLBeacon*)beacon
{
    NSString *proximity;
    switch (beacon.proximity) {
        case CLProximityNear:
            proximity = @"Near";
            break;
        case CLProximityImmediate:
            proximity = @"Immediate";
            break;
        case CLProximityFar:
            proximity = @"Far";
            break;
        case CLProximityUnknown:
        default:
            proximity = @"Unknown";
            break;
    }
    
    NSString *format = @"%@, %@ • %@ • %f • %li";
    return [NSString stringWithFormat:format, beacon.major, beacon.minor, proximity, beacon.accuracy, beacon.rssi];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.detectedBeacons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    CLBeacon *beacon = self.detectedBeacons[indexPath.row];
            
    cell = [tableView dequeueReusableCellWithIdentifier:kBeaconCellIdentifier];
            
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                        reuseIdentifier:kBeaconCellIdentifier];

    cell.textLabel.text = beacon.proximityUUID.UUIDString;
    cell.detailTextLabel.text = [self detailsStringForBeacon:beacon];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textFieldShouldReturn()");
    [self.registerTextField resignFirstResponder];
    [self register];
    return YES;
}

- (IBAction)registerAction:(id)sender {
    NSLog(@"registerAction()");
    if (sender != self.registerButton) return;
    [self.registerTextField resignFirstResponder];
    [self register];
}

- (void)register {
    if (self.registerTextField.text.length > 0) {
        NSLog(@"Got registered name %@", self.registerTextField.text);
        self.registeredName =  self.registerTextField.text;
    }
}
@end
