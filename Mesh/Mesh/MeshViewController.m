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

@property (nonatomic, strong) NSArray *detectedBeacons;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation MeshViewController

- (void)createBeaconRegion
{
    if (self.beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kUUID];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:kIdentifier];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self startRanging];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// TODO(ahogue): Replace this with a call to the server to pull a username for the beacon.
- (NSString *)detailsStringForBeacon:(CLBeacon *)beacon
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

@end
