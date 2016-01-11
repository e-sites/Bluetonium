//
//  Map.swift
//  Bluetonium
//
//  Created by Dick Verbunt on 05/01/16.
//  Copyright © 2015 E-sites. All rights reserved.
//

import Foundation


public protocol MapValue {}
extension NSData: MapValue {}
extension String: MapValue {}
extension UInt8: MapValue {}
extension UInt16: MapValue {}
extension UInt32: MapValue {}


public class Map {
    internal var setMapUUID: String?
    internal var setMapValue: MapValue?
    internal var getMapUUID: String?
    internal var getMapValue: MapValue?
    internal var currentMapUUID = ""
    internal weak var serviceModel: ServiceModel?
    
    public subscript(UUID: String) -> Map {
        currentMapUUID = UUID
        
        return self
    }
    
    /**
     Function will be for every mapped value
     */
    internal func map<T:MapValue>(inout field: T, _ key: String, _ transformer: DataTransformer? = nil) {
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
    private func valueTypeOfField<T:MapValue>(inout field: T) -> Any.Type {
        return Mirror(reflecting: field).subjectType
    }
}


infix operator <- {}

public func <- <T:MapValue>(inout lhs: T, rhs: Map) {
    rhs.map(&lhs, rhs.currentMapUUID)
}

public func <- <T:MapValue>(inout lhs: T, rhs: (Map, DataTransformer)) {
    let (map, transformer) = rhs
    map.map(&lhs, map.currentMapUUID, transformer)
}
