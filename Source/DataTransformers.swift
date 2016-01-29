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
    func transform(dataToValue data: NSData?) -> MapValue
    
    /**
     Function used when writing to the characteristic.
     Transform the Value to NSData
     */
    func transform(valueToData value: MapValue?) -> NSData
}

/**
 Default transformer from NSData to NSData and back.
*/
internal class NSDataDataTransformer: DataTransformer {
    
    func transform(dataToValue data: NSData?) -> MapValue {
        if let data = data {
            return data
        } else {
            return NSData()
        }
    }
    
    func transform(valueToData value: MapValue?) -> NSData {
        if let value = value as? NSData {
            return value
        }
        return NSData()
    }
    
}

/**
 Default transformer from NSData to String and back.
 */
internal class StringDataTransformer: DataTransformer {
    
    func transform(dataToValue data: NSData?) -> MapValue {
        if let data = data {
            if let string = String(data: data, encoding: NSUTF8StringEncoding) {
                return string
            }
        }
        return String()
    }
    
    func transform(valueToData value: MapValue?) -> NSData {
        if let value = value as? String {
            if let data = value.dataUsingEncoding(NSUTF8StringEncoding) {
                return data
            }
        }
        return NSData()
    }
    
}

/**
 Default transformer from NSData to UInt8 and back.
 */
internal class UInt8DataTransformer: DataTransformer {
    
    func transform(dataToValue data: NSData?) -> MapValue {
        guard let data = data else {
            return UInt8()
        }
        var value = UInt8()
        data.getBytes(&value, length: sizeof(UInt8))
        return value
    }
    
    func transform(valueToData value: MapValue?) -> NSData {
        guard var value = value as? UInt8 else {
            return NSData()
        }
        return NSData(bytes: &value, length: sizeof(UInt8))
    }
    
}

/**
 Default transformer from NSData to UInt16 and back.
 */
internal class UInt16DataTransformer: DataTransformer {
    
    func transform(dataToValue data: NSData?) -> MapValue {
        guard let data = data else {
            return UInt16()
        }
        var value = UInt16()
        data.getBytes(&value, length: sizeof(UInt16))
        return value
    }
    
    func transform(valueToData value: MapValue?) -> NSData {
        guard var value = value as? UInt16 else {
            return NSData()
        }
        return NSData(bytes: &value, length: sizeof(UInt16))
    }
    
}

/**
 Default transformer from NSData to UInt32 and back.
 */
internal class UInt32DataTransformer: DataTransformer {
    
    func transform(dataToValue data: NSData?) -> MapValue {
        guard let data = data else {
            return UInt32()
        }
        var value = UInt32()
        data.getBytes(&value, length: sizeof(UInt32))
        return value
    }
    
    func transform(valueToData value: MapValue?) -> NSData {
        guard var value = value as? UInt32 else {
            return NSData()
        }
        return NSData(bytes: &value, length: sizeof(UInt32))
    }
    
}
