//
//  MeshViewController.m
//  Mesh
//
//  Created by ahogue on 10/22/13.
//  Copyright (c) 2013 ahogue. All rights reserved.
//

#import "MeshViewController.h"
#import "MeshBeacon.h"
#import "MeshUser.h"

static NSString * const kBeaconCellIdentifier = @"BeaconCell";
static NSString * const kUUID = @"0D5067C7-E8AD-41D2-A6DE-6C1325936DA0";
static NSString * const kIdentifier = @"MeshIdentifier";

//static NSString * const kMeshAPIHost = @"localhost:8000";
static NSString * const kMeshAPIHost = @"meshserver-env-ppqb2mkh8e.elasticbeanstalk.com/";


@interface MeshViewController ()

@property (weak, nonatomic) IBOutlet UITextField *registerTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;

- (IBAction)registerAction:(id)sender;

@property (nonatomic, strong) NSArray *detectedBeacons;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSString *registeredName;
@property (nonatomic, strong) NSNumber *beaconMajorID;
@property (nonatomic, strong) NSNumber *beaconMinorID;

@property (nonatomic, strong) NSDictionary *detectedUsers;

@end

@implementation MeshViewController

#pragma mark Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupMajorMinorIdentifiers];
    [self startRanging];
    [self initDummyData];
    NSLog(@"%d beacons", [self.detectedBeacons count]);
    self.registerTextField.delegate = self;
    self.beaconTable.dataSource = self;
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
    NSLog(@"idForVendor: %@", idForVendorString);
    NSScanner *majorScanner = [NSScanner scannerWithString:[idForVendorString substringToIndex:8]];
    [majorScanner scanHexInt:&majorID];
    NSScanner *minorScanner = [NSScanner scannerWithString:[idForVendorString substringFromIndex:24]];
    [minorScanner scanHexInt:&minorID];
    self.beaconMajorID = [NSNumber numberWithUnsignedInt:majorID];
    self.beaconMinorID = [NSNumber numberWithUnsignedInt:minorID];
    NSLog(@"Got major,minor IDs: %@,%@", self.beaconMajorID, self.beaconMinorID);
}

- (void)initDummyData {
#if TARGET_IPHONE_SIMULATOR
    NSMutableArray *beacons =
        [[NSMutableArray alloc] initWithObjects:
         [[MeshBeacon alloc] initFromData:[NSNumber numberWithInt:12345] withMinor:[NSNumber numberWithInt:23456]],
         [[MeshBeacon alloc] initFromData:[NSNumber numberWithInt:9876] withMinor:[NSNumber numberWithInt:54321]],
         nil];
    
    [self fetchUsersForBeacons:beacons];
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"didReceiveMemoryWarning");
    // Dispose of any resources that can be recreated.
}

#pragma mark Beacon Broadcasting

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

#pragma mark Beacon Ranging

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"didChangeAuthorizationStatus: %u", status);
    
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"Couldn't turn on ranging: Location services are not enabled.");
        return;
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        NSLog(@"Couldn't turn on ranging: Location services not authorised.");
        return;
    }
}


- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    NSMutableArray *meshBeacons = [NSMutableArray init];
    for (int ii = 0; ii < [beacons count]; ii++) {
        [meshBeacons addObject:[[MeshBeacon alloc] initFromCLBeacon:[beacons objectAtIndex:ii]]];
    }
    [self fetchUsersForBeacons:meshBeacons];
}


// Find the index paths into the table view of removed beacons.
- (NSArray *)indexPathsOfRemovedBeacons:(NSArray *)beacons
{
    NSLog(@"indexPathsOfRemovedBeacons checking %d beacons vs. %d detected", [beacons count], [self.detectedBeacons count]);
    NSMutableArray *indexPaths = nil;
    
    NSUInteger row = 0;
    for (MeshBeacon *existingBeacon in self.detectedBeacons) {
        BOOL stillExists = NO;
        for (MeshBeacon *beacon in beacons) {
            if ((existingBeacon.major.integerValue == beacon.major.integerValue) &&
                (existingBeacon.minor.integerValue == beacon.minor.integerValue)) {
                NSLog(@"%@,%@ still exists", existingBeacon.major, existingBeacon.minor);
                stillExists = YES;
                break;
            }
        }
        if (!stillExists) {
            if (!indexPaths)
                indexPaths = [NSMutableArray new];
            NSLog(@"%@,%@ doesn't exist", existingBeacon.major, existingBeacon.minor);
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
        row++;
    }
    NSLog(@"index paths of removed beacons: %@", indexPaths);
    return indexPaths;
}

// Find the index paths into the table view of newly detected beacons.
- (NSArray *)indexPathsOfInsertedBeacons:(NSArray *)beacons
{
    NSMutableArray *indexPaths = nil;
    
    NSUInteger row = 0;
    for (MeshBeacon *beacon in beacons) {
        BOOL isNewBeacon = YES;
        for (MeshBeacon *existingBeacon in self.detectedBeacons) {
            if ((existingBeacon.major.integerValue == beacon.major.integerValue) &&
                (existingBeacon.minor.integerValue == beacon.minor.integerValue)) {
                NSLog(@"%@,%@ not new beacon", existingBeacon.major, existingBeacon.minor);
                isNewBeacon = NO;
                break;
            }
        }
        if (isNewBeacon) {
            if (!indexPaths)
                indexPaths = [NSMutableArray new];
            NSLog(@"%@,%@ new beacon", beacon.major, beacon.minor);
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
        }
        row++;
    }

    NSLog(@"index paths of inserted beacons: %@", indexPaths);
    return indexPaths;
}

// Generate a set of NSIndexPaths for the existing beacons.
- (NSArray *)indexPathsForBeacons:(NSArray *)beacons
{
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSUInteger row = 0; row < beacons.count; row++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:0]];
    }
    
    return indexPaths;
}

- (NSArray *)filteredBeacons:(NSArray *)beacons
{
    // Filters duplicate beacons out; this may happen temporarily if the originating device changes its Bluetooth id
    NSMutableArray *mutableBeacons = [beacons mutableCopy];
    
    NSMutableSet *lookup = [[NSMutableSet alloc] init];
    for (int index = 0; index < [beacons count]; index++) {
        MeshBeacon *curr = [beacons objectAtIndex:index];
        NSString *identifier = [NSString stringWithFormat:@"%@/%@", curr.major, curr.minor];
        
        // this is very fast constant time lookup in a hash table
        if ([lookup containsObject:identifier]) {
            NSLog(@"Removing duplicate beacon %@", identifier);
            [mutableBeacons removeObjectAtIndex:index];
        } else {
            [lookup addObject:identifier];
        }
    }
    
    return [mutableBeacons copy];
}

- (void)fetchUsersForBeacons:(NSArray*)beacons {
    NSMutableArray *majorMinorIDs = [[NSMutableArray alloc] init];
    for (int ii = 0; ii < [beacons count]; ii++) {
        MeshBeacon *curr = [beacons objectAtIndex:ii];
        [majorMinorIDs addObject:[NSString stringWithFormat:@"%@,%@", curr.major, curr.minor]];
    }
    NSString *urlAsString = [NSString stringWithFormat:@"http://%@/find_users/%@",
                             kMeshAPIHost, [majorMinorIDs componentsJoinedByString:@";"]];

    NSLog(@"fetchUsersForBeacons url: %@", urlAsString);
    NSURL *url = [[NSURL alloc] initWithString:urlAsString];
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            [self fetchUsersHandleError:connectionError];
        } else {
            [self fetchUsersHandleSuccess:data withBeacons:beacons];
        }
    }];

}

- (void)fetchUsersHandleError:(NSError*)error {
    NSLog(@"Error handling fetch_users: %@", error);
}

- (void)fetchUsersHandleSuccess:(NSData*)data
                    withBeacons:(NSArray*)beacons {
    [self parseUserJSON:data];

    NSArray *filteredBeacons = [self filteredBeacons:beacons];
    
    if (filteredBeacons.count == 0) {
        NSLog(@"No beacons found nearby.");
    } else {
        NSLog(@"Found %lu beacons.", (unsigned long)[filteredBeacons count]);
    }
    
    NSArray *deletedRows = [self indexPathsOfRemovedBeacons:filteredBeacons];
    NSArray *insertedRows = [self indexPathsOfInsertedBeacons:filteredBeacons];
    NSArray *reloadedRows = nil;
    if (!deletedRows && !insertedRows) {
        NSLog(@"foo");
        reloadedRows = [self indexPathsForBeacons:filteredBeacons];
    }
    
    self.detectedBeacons = filteredBeacons;
    
    [self.beaconTable beginUpdates];
    if (insertedRows)
        [self.beaconTable insertRowsAtIndexPaths:insertedRows withRowAnimation:UITableViewRowAnimationFade];
    if (deletedRows)
        [self.beaconTable deleteRowsAtIndexPaths:deletedRows withRowAnimation:UITableViewRowAnimationFade];
    if (reloadedRows)
        [self.beaconTable reloadRowsAtIndexPaths:reloadedRows withRowAnimation:UITableViewRowAnimationNone];
    [self.beaconTable endUpdates];
}

// Parse the JSON response for /find_users and return a dictionary mapping "major,minor" to MeshUser*.
-(void)parseUserJSON:(NSData*)data {
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    NSError *error = nil;
    NSMutableDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error != nil) {
        NSLog(@"Error parsing find_users response: %@", error);
        return;
    }
    NSMutableDictionary *users = [[NSMutableDictionary alloc] init];
    for (NSString *majorMinor in parsedObject) {
        MeshUser *user = [[MeshUser alloc] init];
        NSDictionary *userDict = [parsedObject objectForKey:majorMinor];
        user.name = [userDict objectForKey:@"name"];
        user.major = [userDict objectForKey:@"major"];
        user.minor = [userDict objectForKey:@"minor"];
        [users setObject:user forKey:majorMinor];
        
        NSLog(@"%@ => %@", majorMinor, [user toString]);
    }
    self.detectedUsers = users;
}

#pragma mark Table View Management

- (NSString *)detailsStringForBeacon:(MeshBeacon*)beacon
{
    NSString *format = @"%@, %@ • %f";
    return [NSString stringWithFormat:format, beacon.major, beacon.minor, beacon.accuracy];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"numberOfRowsInSection: %d", self.detectedBeacons.count);
    return self.detectedBeacons.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    MeshBeacon *beacon = self.detectedBeacons[indexPath.row];
            
    cell = [tableView dequeueReusableCellWithIdentifier:kBeaconCellIdentifier];
            
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                        reuseIdentifier:kBeaconCellIdentifier];

    MeshUser *user = [self.detectedUsers valueForKey:[NSString stringWithFormat:@"%@,%@", beacon.major, beacon.minor]];
    cell.textLabel.text = user.name;
    cell.detailTextLabel.text = [self detailsStringForBeacon:beacon];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    return cell;
}

#pragma mark User Registration

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
        NSString *urlAsString = [NSString stringWithFormat:@"http://%@/register?name=%@&major=%@&minor=%@",
                                 kMeshAPIHost, self.registeredName, self.beaconMajorID, self.beaconMinorID];
        NSLog(@"Register url: %@", urlAsString);
        NSURL *url = [[NSURL alloc] initWithString:urlAsString];
        [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (connectionError) {
                [self registerHandleError:connectionError];
            } else {
                [self registerHandleSuccess:data];
            }
        }];
    }
}

- (void)registerHandleError:(NSError*)error {
    NSLog(@"Error handling registration: %@", error);
}

- (void) registerHandleSuccess:(NSData*)data {
    NSError *error = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error != nil) {
        NSLog(@"Error parsing register response: %@", error);
        return;
    }
    for (NSString *key in parsedObject) {
        NSLog(@"%@ => %@", key, [parsedObject valueForKey:key]);
    }
    // TODO: actually do something with the registered user?
    // TODO: display a confirmation to the user
}

@end
