//
//  DataTransformers.swift
//  Bluetonium
//
//  Created by Dick Verbunt on 29/12/15.
//  Copyright © 2015 E-sites. All rights reserved.
//

import Foundation

/**
    Protocol that should be used when writing your own DataTransformer.
*/
public protocol DataTransformer {
    
    /**
     Function used when reading from the characteristic.
     Transform Data to the Value
    */
    func transform(dataToValue data: Data?) -> MapValue
    
    /**
     Function used when writing to the characteristic.
     Transform the Value to Data
     */
    func transform(valueToData value: MapValue?) -> Data
}


/**
 Default transformer from Data to Data and back.
*/
class DataDataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        return data ?? Data()
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        if let value = value as? Data {
            return value
        }
        return Data()
    }
    
}

/**
 Default transformer from Data to String and back.
 */
class StringDataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        if let data = data {
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                return string
            }
        }
        return String()
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        if let value = value as? String {
            if let data = value.data(using: String.Encoding.utf8) {
                return data
            }
        }
        return Data()
    }
    
}

/**
 Default transformer from Data to UInt8 and back.
 */
class UInt8DataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        guard let data = data else {
            return UInt8()
        }
        
        return data.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> UInt8 in
            return ptr.pointee
        }
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        guard var value = value as? UInt8 else {
            return Data()
        }
        return Data(buffer: UnsafeBufferPointer(start: &value, count: MemoryLayout<UInt8>.size))
    }
    
}

/**
 Default transformer from Data to UInt16 and back.
 */
class UInt16DataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        guard let data = data else {
            return UInt16()
        }
        
        return data.withUnsafeBytes { (ptr: UnsafePointer<UInt16>) -> UInt16 in
            return ptr.pointee
        }
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        guard var value = value as? UInt16 else {
            return Data()
        }
        return Data(buffer: UnsafeBufferPointer(start: &value, count: MemoryLayout<UInt16>.size))
    }
    
}

/**
 Default transformer from Data to UInt32 and back.
 */
class UInt32DataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        guard let data = data else {
            return UInt32()
        }
        
        return data.withUnsafeBytes { (ptr: UnsafePointer<UInt32>) -> UInt32 in
            return ptr.pointee
        }
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        guard var value = value as? UInt32 else {
            return Data()
        }
        return Data(buffer: UnsafeBufferPointer(start: &value, count: MemoryLayout<UInt32>.size))
    }
    
}
