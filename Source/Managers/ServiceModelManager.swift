//
//  ServiceModelManager.swift
//  Bluetonium
//
//  Created by Dominggus Salampessy on 23/12/15.
//  Copyright © 2015 E-sites. All rights reserved.
//

import Foundation
import CoreBluetooth

class ServiceModelManager: NSObject, CBPeripheralDelegate {
    
    fileprivate(set) weak var peripheral: CBPeripheral?
    fileprivate(set) var registeredServiceModels: [ServiceModel]
    
    // MARK: Initializers
    
    init(peripheral: CBPeripheral) {
        self.registeredServiceModels = []
        self.peripheral = peripheral
        super.init()
    }
    
    /**
     Discover all the registered services.
     Only the registered BTServiceModel subclasses will be discovered.
     */
    func discoverRegisteredServices() {
        if registeredServiceModels.count == 0 {
            return
        }
        
        let UUIDs = registeredServiceModels.map { CBUUID(string: $0.serviceUUID) }
        peripheral?.discoverServices(UUIDs)
    }
    
    // MARK: functions
    
    /**
     Register a `BTServiceModel` subclass.
        
     - parameter serviceModel: The BTServiceModel to register.
     */
    func register(serviceModel: ServiceModel) {
        if !registeredServiceModels.contains(serviceModel) {
            registeredServiceModels.append(serviceModel)
            serviceModel.serviceModelManager = self
        }
    }
    
    /**
     Check if a specific `CBCharacteristic` is available.
        
     - parameter characteristicUUID: The UUID of the characteristic.
     - parameter serviceUUID: The UUID of the service.
     
     - returns: True if the `CBCharacteristic` is available.
     */
    func characteristicAvailable(_ characteristicUUID: String, serviceUUID: String) -> Bool {
        return characteristic(characteristicUUID, serviceUUID: serviceUUID) != nil
    }
    
    /**
     Perform a readValue call on the peripheral.
        
     - parameter characteristicUUID: The UUID of the characteristic.
     - parameter serviceUUID: The UUID of the service.
     */
    func readValue(_ characteristicUUID: String, serviceUUID: String) {
        if let characteristic = characteristic(characteristicUUID, serviceUUID: serviceUUID) {
            peripheral?.readValue(for: characteristic)
        }
    }
    
    /**
     Perform a writeValue call on the peripheral.
    
     - parameter value: The data to write.
     - parameter characteristicUUID: The UUID of the characteristic.
     - parameter serviceUUID: The UUID of the service.
     */
    func writeValue(_ value: Data, toCharacteristicUUID characteristicUUID: String, serviceUUID: String, response: Bool) {
        if let characteristic = characteristic(characteristicUUID, serviceUUID: serviceUUID) {
            peripheral?.writeValue(value, for: characteristic, type: response ? .withResponse : .withoutResponse)
        }
    }
    
    /**
     Reset all the registered BTServiceModel's.
    */
    func resetServices() {
        for serviceModel in registeredServiceModels {
            serviceModel.resetService()
        }
    }

    /**
     Enables or disables notify messages for a specific characteristic / servicemodel

     - parameter serviceModel: The `ServiceModel`
     - parameter enabled: `Bool`
     - parameter characteristicUUID: The characteristic uuid
     */
    func setNotify(serviceModel: ServiceModel, enabled: Bool, characteristicUUID: String) {
        guard let characteristic = characteristic(characteristicUUID, serviceUUID: serviceModel.serviceUUID) else {
            return
        }
        peripheral?.setNotifyValue(enabled, for: characteristic)
    }
    
    // MARK: Private functions
    
    /**
     Get the `BTServiceModel` subclass in the the registered serviceModels.
        
     - parameter UUID: The UUID of the `BTServiceModel` to return.
        
     - returns: Returns a registered `BTServiceModel` subclass if found.
     */
    fileprivate func serviceModel(withUUID uuid: String) -> ServiceModel? {
        return registeredServiceModels.filter { $0.serviceUUID == uuid }.first
    }
    
    /**
     Get the `CBCharacteristic` with a specific UUID string of a CBService.
     
     - parameter characteristicUUID: The UUID of the `CBCharacteristic` to lookup.
     - parameter serviceUUID: The UUID of the `CBService` to lookup.
     
     - returns: A `CBCharacteristic` if found, nil if nothing found.
     */
    fileprivate func characteristic(_ characteristicUUID: String, serviceUUID: String) -> CBCharacteristic? {
        guard let service = service(withServiceUUID: serviceUUID) else {
            return nil
        }
        
        guard let characteristics = service.characteristics else {
            return nil
        }
        
        return characteristics.filter { $0.uuid.uuidString == characteristicUUID }.first
    }
    
    /**
     Get the `CBService` with a specific UUID string.
        
     - parameter serviceUUID: The UUID of the `CBService` to lookup.
     
     - returns: A `CBService` if found, nil if nothing found.
     */
    fileprivate func service(withServiceUUID serviceUUID: String) -> CBService? {
        guard let services = peripheral?.services else {
            return nil
        }
        return services.filter { $0.uuid.uuidString == serviceUUID }.first
    }
    
    // MARK: CBPeripheralDelegate
    
    @objc func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }

        for service in services {
            guard let serviceModel = serviceModel(withUUID: service.uuid.uuidString) else {
                continue
            }
            // Perform discover characteristics only for registered characteristics.
            let characteristics = serviceModel.characteristicUUIDs.cbUuids
            serviceModel.serviceAvailable = true
            peripheral.discoverCharacteristics(characteristics, for: service)
        }
    }

    @objc func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let serviceModel = serviceModel(withUUID: service.uuid.uuidString), let characteristics = service.characteristics else {
            return
        }

        for characteristic in characteristics {
            // Check with correct ServiceModel if it should register for value changes.
            if serviceModel.registerNotifyForCharacteristic(withUUID: characteristic.uuid.uuidString) {
                peripheral.setNotifyValue(true, for: characteristic)
            } else {
                peripheral.setNotifyValue(false, for: characteristic)
            }
            
            // Notify ServiceModel the characteristic did become available.
            serviceModel.characteristicAvailable(withUUID: characteristic.uuid.uuidString)
        }
    }

    @objc func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) { }

    @objc func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let serviceModel = serviceModel(withUUID: characteristic.service.uuid.uuidString) else {
            return
        }
        
        // Update the value of the changed characteristic.
        serviceModel.didRead(characteristic.value, withUUID: characteristic.uuid.uuidString)
    }
    
    @objc func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}
