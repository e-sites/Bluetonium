//
//  CBCharacteristicMock.m
//  Bluetonium
//
//  Created by Bas van Kuijck on 29/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

#import "CBCharacteristicMock.h"
#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

@implementation CBCharacteristicMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        _characteristic = mock(CBCharacteristic.class);
    }
    return self;
}

- (void)setValue:(NSData *)value
{
    _value = value;
    stubProperty(_characteristic, value, self.value);
}


- (void)setUUID:(CBUUID *)uuid
{
    _UUID = uuid;
    stubProperty(_characteristic, UUID, self.UUID);
}


- (void)setService:(CBService *)service
{
    _service = service;
    stubProperty(_characteristic, service, self.service);
}

@end
