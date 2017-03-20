//
//  ManagerDelegate.swift
//  Bluetonium
//
//  Created by Bas van Kuijck on 20/03/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

import Foundation

public protocol ManagerDelegate: class {
    
    /**
     Called when the `Manager` did find a peripheral and did add it to the foundDevices array.
     */
    func manager(_ manager: Manager, didFindDevice device: Device)
    
    /**
     Called when the `Manager` is trying to connect to device
     */
    func manager(_ manager: Manager, willConnectToDevice device: Device)
    
    /**
     Called when the `Manager` did connect to the device.
     */
    func manager(_ manager: Manager, connectedToDevice device: Device)
    
    /**
     Called when the `Manager` did disconnect from the device.
     Retry will indicate if the Manager will retry to connect when it becomes available.
     */
    func manager(_ manager: Manager, disconnectedFromDevice device: Device, willRetry retry: Bool)
    
}
