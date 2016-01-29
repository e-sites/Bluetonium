//
//  Device.swift
//  Bluetonium
//
//  Created by Dominggus Salampessy on 23/12/15.
//  Copyright © 2015 E-sites. All rights reserved.
//

import Foundation
import CoreBluetooth

/**
 Equatable support.
 */
public func ==(lhs: Device, rhs: Device) -> Bool {
    return lhs.peripheral.identifier == rhs.peripheral.identifier
}

/**
 A `Device` will represent a CBPeripheral.
 When registering ServiceModels on this device it will automaticly map the characteristics to the correct value.
*/
public class Device: Equatable {
    
    // An array of all registered `ServiceModel` subclasses
    public var registedServiceModels: [ServiceModel] {
        get {
            return serviceModelManager.registeredServiceModels
        }
    }
    // The peripheral it represents.
    private(set) public var peripheral: CBPeripheral
    // The ServiceModelManager that will manage all registered `ServiceModels`
    private(set) internal var serviceModelManager: ServiceModelManager
    
    // MARK: Initializers
    
    /**
     Initalize the `Device` with a Peripheral.
    
     - parameter peripheral: The peripheral it will represent
     */
    public init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.serviceModelManager = ServiceModelManager(withPeripheral: peripheral)
    }
    
    // MARK: Public functions
    
    /**
     Register a `ServiceModel` subclass.
     Register before connecting to the device.
    
     - parameter serviceModel: The ServiceModel subclass to register.
     */
    public func registerServiceModel(serviceModel: ServiceModel) {
        serviceModelManager.registerServiceModel(serviceModel)
    }
    
    // MARK: Internal functions
    
    /**
     Register serviceManager as delegate of the peripheral.
     This should be done just before connecting/
     If done at initalizing it will override the existing peripheral delegate.
    */
    internal func registerServiceManager() {
        peripheral.delegate = serviceModelManager
    }
    
}