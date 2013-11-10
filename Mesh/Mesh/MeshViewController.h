//
//  MeshViewController.h
//  Mesh
//
//  Created by ahogue on 10/22/13.
//  Copyright (c) 2013 ahogue. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;
@import CoreBluetooth;

@interface MeshViewController : UIViewController <CLLocationManagerDelegate, CBPeripheralManagerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITableView *beaconTable;

@end
