//
//  CBServiceMock.h
//  Bluetonium
//
//  Created by Bas van Kuijck on 29/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

@import Foundation;
@import CoreBluetooth;

@interface CBServiceMock : NSObject
@property (readonly, nonatomic, strong) CBService *service;
@property (nonatomic, strong) CBUUID *UUID;
@end
