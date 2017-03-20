//
//  Map.swift
//  Bluetonium
//
//  Created by Dick Verbunt on 05/01/16.
//  Copyright © 2015 E-sites. All rights reserved.
//

import Foundation


public protocol MapValue {
    init()
}

extension Data: MapValue {}
extension String: MapValue {}
extension UInt8: MapValue {}
extension UInt16: MapValue {}
extension UInt32: MapValue {}

open class Map {
    var setMapUUID: String?
    var setMapValue: MapValue?
    var getMapUUID: String?
    var getMapValue: MapValue?
    var currentMapUUID = ""
    weak var serviceModel: ServiceModel?
    
    open subscript(uuid: String) -> Map {
        currentMapUUID = uuid
        
        return self
    }
    
    /**
     Function will be for every mapped value
     */
    func map<T:MapValue>(_ field: inout T, _ key: String, _ transformer: DataTransformer? = nil) {
        // Register UUID and type of the field in service model.
        serviceModel?.register(withUUID: currentMapUUID, valueType: valueTypeOfField(&field), transformer: transformer)
        
        // Check if the value should be set.
        if setMapUUID == key && setMapValue != nil {
            field = setMapValue as! T
        }
        
        // Check if it should get a value.
        if getMapUUID == key {
            getMapValue = field
        }
    }
    
    /**
     Return the type of a property.

     - parameter field: The property

     - return: The type of the property.
     */
    private func valueTypeOfField<T:MapValue>(_ field: inout T) -> Any.Type {
        return Mirror(reflecting: field).subjectType
    }
}


infix operator <-

public func <- <T:MapValue>(lhs: inout T, rhs: Map) {
    rhs.map(&lhs, rhs.currentMapUUID)
}

public func <- <T:MapValue>(lhs: inout T, rhs: (Map, DataTransformer)) {
    let (map, transformer) = rhs
    map.map(&lhs, map.currentMapUUID, transformer)
}
