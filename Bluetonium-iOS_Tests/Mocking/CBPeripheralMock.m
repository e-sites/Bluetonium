//
//  CBPeripheralMock.m
//  Bluetonium-iOS_Tests
//
//  Created by Bas van Kuijck on 29/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

#import "CBPeripheralMock.h"
#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

@implementation CBPeripheralMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        _peripheral = mock(CBPeripheral.class);
        stubProperty(_peripheral, state, @(CBPeripheralStateDisconnected));
    }
    return self;
}

- (void)setName:(NSString *)name
{
    _name = [name copy];
    stubProperty(_peripheral, name, self.name);
}

- (void)setIdentifier:(NSUUID *)identifier
{
    _identifier = identifier;
    stubProperty(_peripheral, identifier, self.identifier);
}

- (void)setState:(CBPeripheralState)state
{
    _state = state;
    stubProperty(_peripheral, state, @(self.state));
}

- (void)setServices:(NSArray<CBService *> *)services
{
    _services = services;
    stubProperty(_peripheral, services, self.services);
}

@end
