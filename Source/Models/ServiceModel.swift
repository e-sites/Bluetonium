//
//  ServiceModel.swift
//  Bluetonium
//
//  Created by Dominggus Salampessy on 23/12/15.
//  Copyright © 2015 E-sites. All rights reserved.
//

import Foundation
/**
 Equatable support.
 */
public func ==(lhs: ServiceModel, rhs: ServiceModel) -> Bool {
    return lhs.serviceUUID == rhs.serviceUUID
}


open class ServiceModel: Equatable {
    
    // MARK: Public properties
    
    // When a serivce is discovered on the peripheral it will be set to True.
    // When the peripheral is disconnected it will be set to False.
    public internal(set) var serviceAvailable = false {
        didSet {
            if oldValue == serviceAvailable {
                return
            }
            DispatchQueue.main.async {
                self.serviceModelDidChangeAvailableState(self.serviceAvailable)
            }
        }
    }
    // When all mapped characteristics are available it will be set to True.
    // When the peripheral is disconnected it will be ste to False.
    public fileprivate(set) var serviceReady = false {
        didSet {
            if oldValue == serviceReady {
                return
            }
            DispatchQueue.main.async {
                self.serviceModelDidChangeReadyState(self.serviceReady)
            }
        }
    }
    
    // MARK: properties
    
    weak var serviceModelManager: ServiceModelManager?
    var valueTypeMapping = [String: Any.Type]()
    var transformerMapping = [String: DataTransformer]()
    var characteristicUUIDs: [String] {
        return Array(valueTypeMapping.keys)
    }
    
    // MARK: Private properties
    
    fileprivate let map = Map()
    fileprivate var readCompletionHandlers: [String: [ReadCompletionHandler]] = [:]
    
    // MARK: Initalizers
    
    required public init() {
        map.serviceModel = self
        
        // Prefill characteristicUUIDs.
        mapping(map)
    }
    
    // MARK: Required public functions
    
    /**
     Function that needs to be subclassed.
     Return the UUID of the service it represents.
     */
    open var serviceUUID:String {
        fatalError("Must override this function in your subclass of `BTServiceModel`")
    }
    
    /**
     Function that needs to be subclassed.
     In this function you can create the mapping between UUID and the actual instance variable.
     */
    open func mapping(_ map: Map) {
        fatalError("Must override this function in your subclass of `BTServiceModel`")
    }
    
    // MARK: Helper functions
    
    /**
     Read the value of the characteristic.
     
     - parameter uuid: The UUID of the characteristic to read.
     - parameter completion: Completion block called after the read is done.
     */
    public func readValue(withUUID uuid: String, completion: ReadCompletionHandler? = nil) {
        serviceModelManager?.readValue(uuid, serviceUUID: serviceUUID)
        
        if let completion = completion {
            add(readCompletionHandler: completion, forUUID: uuid)
        }
    }
    
    /**
     Write a value to the characteristic.
     Before calling this, first set the value on your ServiceModel subclass.
     
     - parameter uuid: The UUID of the characteristic to send.
     - parameter response: Boolean to send a write with(out) response.
     */
    public func writeValue(withUUID uuid: String, response: Bool = false) {
        let value = getValueInServiceModel(withUUID: uuid)
        
        guard let dataTransformer = transformer(forUUID: uuid) else {
            return
        }
        
        let data = dataTransformer.transform(valueToData: value)
        serviceModelManager?.writeValue(data, toCharacteristicUUID: uuid, serviceUUID: serviceUUID, response: response)
    }
    
    /**
     Helper method to write to multiple characteristics.
     
     - parameter UUIDs: An array of Strings of the UUIDs to write.
     - paramter response: Boolean to send a write with(out) response.
     */
    public func writeValues(withUUIDs uuids: [String], response: Bool = false) {
        uuids.forEach {
            writeValue(withUUID: $0, response: response)
        }
    }
    
    /**
     Called after a characteristic became available.
     It can be used to register a notify on the characteristic.
     */
    open func registerNotifyForCharacteristic(withUUID uuid: String) -> Bool {
        return false
    }
    
    /**
     Called when a characteristic became available.
     Afther this call it's possible to read and write to this characteristic.
     */
    open func characteristicBecameAvailable(withUUID uuid: String) {
        
    }
    
    /**
     Called when a value of a characteristic value is read or updated.
     Can be because of a read call or due to a notify.
     */
    open func characteristicDidUpdateValue(withUUID uuid: String) {
        
    }
    
    /**
     Called when the serviceAvailable state changed.
     */
    open func serviceModelDidChangeAvailableState(_ available: Bool) {
        
    }
    
    /**
     Called when the serviceReady state changed.
     */
    open func serviceModelDidChangeReadyState(_ ready: Bool) {
        
    }
}


extension ServiceModel {
    
    public typealias ReadCompletionHandler = ((_ value: MapValue) -> Void)
    
    /**
     Called by the `Map` object.
     Adds the UUID and valueType of the instance variable it represents to an dictionary.
     Also adds custom DataTransfromers to an array if they are provided.
     */
    func register(withUUID uuid: String, valueType: Any.Type, transformer: DataTransformer?) {
        if valueTypeMapping[uuid] == nil {
            valueTypeMapping[uuid] = valueType
        }
        if transformerMapping[uuid] == nil, let transformer = transformer {
            transformerMapping[uuid] = transformer
        }
    }
    
    /**
     Called by the `ServiceModelManager`.
     Will get the correct DataTransformer and set the value to the instance variable.
     After that is will call the completion block (if available) and other helper functions.
     */
    func didRead(_ data: Data?, withUUID uuid: String) {
        guard let dataTransformer = transformer(forUUID: uuid) else {
            return
        }
        let value = dataTransformer.transform(dataToValue: data)
        setValueInServiceModel(value, withUUID: uuid)
        
        // Call convenience function.
        characteristicDidUpdateValue(withUUID: uuid)
        
        // Call all existing completion blocks for this read.
        callReadCompletionHandlers(withValue: value, forUUID: uuid)
        
    }
    
    /**
     Called by the `ServiceModelManager` once a characteristic became available.
     */
    func characteristicAvailable(withUUID uuid: String) {
        if !serviceReady && allCharacteristicsAvailable {
            serviceReady = true
        }
        
        characteristicBecameAvailable(withUUID: uuid)
    }
    
    /**
     Reset the `ServiceModel` and make it unavailable.
     Called when the connection is lost with the peripheral.
     */
    func resetService() {
        serviceReady = false
        serviceAvailable = false
    }
    
    // MARK: Private functions
    
    /**
     Return the correct DataTransformer.
     A custom DataTransformer if provided.
     Or a default DataTransformer if the type is supported.
     */
    fileprivate func transformer(forUUID uuid: String) -> DataTransformer? {
        // Return custom transformer if available.
        if let transformer = transformerMapping[uuid] {
            return transformer
        }
        
        // Get the a default transformer based on the type of the property.
        guard let valueType = valueType(forUUID: uuid) else {
            return nil
        }
        if valueType == String?.self || valueType == String.self {
            return StringDataTransformer()
            
        } else if valueType == UInt8?.self || valueType == UInt8.self {
            return UIntDataTransformer<UInt8>()
            
        } else if valueType == UInt16?.self || valueType == UInt16.self {
            return UIntDataTransformer<UInt16>()
            
        } else if valueType == UInt32?.self || valueType == UInt32.self {
            return UIntDataTransformer<UInt32>()
            
        } else if valueType == Data?.self || valueType == Data.self {
            return DataDataTransformer()
        }
        return nil
    }
    
    /**
     Returns the valueType of a characteristic.
     */
    fileprivate func valueType(forUUID uuid: String) -> Any.Type? {
        return valueTypeMapping[uuid]
    }
    
    /**
     Setting a value on the ServiceModel.
     It will place the value in the `Map` object before calling the mapping function.
     The mapping function will loop through all instance variables.
     Once it matches the same UUID it will copy the value to the actual instance variable.
     */
    fileprivate func setValueInServiceModel(_ value: MapValue?, withUUID UUID: String) {
        // Store UUID and value in Map.
        map.setMapUUID = UUID
        map.setMapValue = value
        
        // Call mapping function.
        mapping(map)
        
        // Clean UUID and value from map to prevent errors.
        map.setMapUUID = nil
        map.setMapValue = nil
    }
    
    /**
     Get a value from the ServiceModel.
     It will register wich value it should get on the `Map` object.
     The mapping function will loop through all the instance variables.
     Once it matches the same UUID it will get the value and place it in the `Map` object.
     The value of the `Map` object will be returned.
     */
    fileprivate func getValueInServiceModel(withUUID uuid: String) -> MapValue? {
        // Register the correct UUID to get the value from.
        map.getMapUUID = uuid
        
        // Call mapping function.
        mapping(map)
        
        // Clean UUID and get the value.
        map.getMapUUID = nil
        return map.getMapValue
    }
    
    /**
     Add a completion handler to the Dictionary.
     Multiple completion blocks can be registered for the same UUID.
     */
    fileprivate func add(readCompletionHandler completionHandler: @escaping ReadCompletionHandler, forUUID uuid: String) {
        if var completionHandlers = readCompletionHandlers[uuid] {
            completionHandlers.append(completionHandler)
            readCompletionHandlers[uuid] = completionHandlers
        } else {
            readCompletionHandlers[uuid] = [completionHandler]
        }
    }
    
    /**
     Call all registered completion blocks for that UUID.
     Multiple completion blocks can be called for the same UUID.
     */
    fileprivate func callReadCompletionHandlers(withValue value: MapValue, forUUID uuid: String) {
        guard let completionHandlers = readCompletionHandlers[uuid] else {
            return
        }
        
        for completionHandler in completionHandlers {
            completionHandler(value)
        }
        readCompletionHandlers[uuid] = nil
    }
    
    /**
     Check if all characteristics are available.
     */
    fileprivate var allCharacteristicsAvailable:Bool {
        for characteristicUUID in characteristicUUIDs {
            if serviceModelManager?.characteristicAvailable(characteristicUUID, serviceUUID: serviceUUID) == false {
                return false
            }
        }
        return true
    }
}
