//
//  CBPeripheralMock.h
//  Bluetonium-iOS_Tests
//
//  Created by Bas van Kuijck on 29/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@interface CBPeripheralMock : NSObject
@property (readonly, nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSUUID *identifier;
@property (nonatomic, readwrite) CBPeripheralState state;

@end
