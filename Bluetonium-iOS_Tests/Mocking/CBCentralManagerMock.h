//
//  CBCentralManagerMock.h
//  Bluetonium
//
//  Created by Bas van Kuijck on 29/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@interface CBCentralManagerMock : NSObject
@property (readonly, nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, readwrite) CBManagerState state;
@end
