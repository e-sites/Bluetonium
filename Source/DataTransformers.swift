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
     Transform NSData to the Value
    */
    func transform(dataToValue data: Data?) -> MapValue
    
    /**
     Function used when writing to the characteristic.
     Transform the Value to NSData
     */
    func transform(valueToData value: MapValue?) -> Data
}

/**
 Default transformer from NSData to NSData and back.
*/
internal class NSDataDataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        if let data = data {
            return data as MapValue
        } else {
            return Data() as MapValue
        }
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        if let value = value as? Data {
            return value
        }
        return Data()
    }
    
}

/**
 Default transformer from NSData to String and back.
 */
internal class StringDataTransformer: DataTransformer {
    
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
 Default transformer from NSData to UInt8 and back.
 */
internal class UInt8DataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        guard let data = data else {
            return UInt8()
        }
        var value = UInt8()
        (data as NSData).getBytes(&value, length: MemoryLayout<UInt8>.size)
        return value
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        guard var value = value as? UInt8 else {
            return Data()
        }
        return Data(bytes: &value, count: MemoryLayout<UInt8>.size)
    }
    
}

/**
 Default transformer from NSData to UInt16 and back.
 */
internal class UInt16DataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        guard let data = data else {
            return UInt16()
        }
        var value = UInt16()
        (data as NSData).getBytes(&value, length: MemoryLayout<UInt16>.size)
        return value
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        guard var value = value as? UInt16 else {
            return Data()
        }
        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
    }
    
}

/**
 Default transformer from NSData to UInt32 and back.
 */
internal class UInt32DataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        guard let data = data else {
            return UInt32()
        }
        var value = UInt32()
        (data as NSData).getBytes(&value, length: MemoryLayout<UInt32>.size)
        return value
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        guard var value = value as? UInt32 else {
            return Data()
        }
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
    
}
