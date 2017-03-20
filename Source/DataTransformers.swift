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
        guard let value = value as? Data else {
            return Data()
        }
        return value
    }
    
}

/**
 Default transformer from Data to String and back.
 */
class StringDataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        guard let data = data,
            let string = String(data: data, encoding: String.Encoding.utf8) else {
                return String()
        }
        return string
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        guard let value = value as? String,
            let data = value.data(using: .utf8) else {
                return Data()
        }
        return data
    }
    
}

/**
 UInt transformer from Data to String and back.
 */
class UIntDataTransformer<T:MapValue> : DataTransformer where T:UnsignedInteger {
    func transform(dataToValue data: Data?) -> MapValue {
        guard let data = data else {
            return T()
        }
        var value = T()
        (data as NSData).getBytes(&value, length: MemoryLayout<T>.size)
        return value
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        guard var value = value as? T else {
            return Data()
        }
        return Data(bytes: &value, count: MemoryLayout<UInt8>.size)
    }
}
