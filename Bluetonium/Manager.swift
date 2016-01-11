//
//  Manager.swift
//  Bluetonium
//
//  Created by Dominggus Salampessy on 23/12/15.
//  Copyright © 2015 E-sites. All rights reserved.
//

import Foundation
import CoreBluetooth

public class Manager: NSObject, CBCentralManagerDelegate {
    
    public var bluetoothEnabled: Bool {
        get {
            return centralManager?.state == .PoweredOn
        }
    }
    private(set) public var scanning = false
    private(set) public var connectedDevice: Device?
    private(set) public var foundDevices: [Device]!
    public weak var delegate: ManagerDelegate?
    
    private var centralManager: CBCentralManager?
    private var disconnecting = false
    private let dispatchQueue = dispatch_queue_create(ManagerConstants.dispatchQueueLabel, nil)
    
    // MARK: Initializers
    
    public init(background: Bool = false) {
        super.init()
        
        let options: [String: String]? = background ? [CBCentralManagerOptionRestoreIdentifierKey: ManagerConstants.restoreIdentifier] : nil
        foundDevices = []
        centralManager = CBCentralManager(delegate: self, queue: dispatchQueue, options: options)
    }
    
    // MARK: Public functions
    
    /**
     Start scanning for devices advertising with a specific service.
     The services can also be nil this will return all found devices.
     Found devices will be returned in the foundDevices array.
    
     - parameter services: The UUID of the service the device is advertising with, can be nil.
    */
    public func startScanForDevices(advertisingWithServices services: [String]? = nil) {
        if scanning == true {
            return
        }
        scanning = true
        
        foundDevices.removeAll()
        centralManager?.scanForPeripheralsWithServices(services?.CBUUIDs(), options: nil)
    }
    
    /**
     Stop scanning for devices.
     Only possible when it's scanning.
     */
    public func stopScanForDevices() {
        scanning = false
        
        centralManager?.stopScan()
    }
    
    /**
     Connect with a device. This device is returned from the foundDevices list.
    
     - parameter device: The device to connect with.
     */
    public func connectWithDevice(device: Device) {
        // Only allow connecting when it's not yet connected to another device.
        if connectedDevice != nil || disconnecting {
            return
        }
        
        connectedDevice = device
        connectToDevice()
    }
    
    /**
     Disconnect from the connected device.
     Only possible when not connected to a device.
     */
    public func disconnectFromDevice() {
        // Reset stored UUID.
        storeConnectedUUID(nil)
        
        guard let peripheral = connectedDevice?.peripheral else {
            return
        }
        
        if peripheral.state != .Connected {
            connectedDevice = nil
        } else {
            disconnecting = true
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: Private functions
    
    private func connectToDevice() {
        if let peripheral = connectedDevice?.peripheral {
            // Store connected UUID, to enable later connection to the same peripheral.
            storeConnectedUUID(peripheral.identifier.UUIDString)
            
            if peripheral.state == .Disconnected {
                
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    // Send callback to delegate.
                    self.delegate?.manager(self, willConnectToDevice: self.connectedDevice!)
                }
                
                centralManager?.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(bool: true)])
            }
        }
    }
    
    /**
     Store the connectedUUID in the UserDefaults.
     This is to restore the connection after the app restarts or runs in the background.
     */
    private func storeConnectedUUID(UUID: String?) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(UUID, forKey: ManagerConstants.UUIDStoreKey)
        defaults.synchronize()
    }
    
    /**
     Returns the stored UUID if there is one.
     */
    private func storedConnectedUUID() -> String? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.objectForKey(ManagerConstants.UUIDStoreKey) as? String
    }
    
    // MARK: CBCentralManagerDelegate
    
    @objc public func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        print("willRestoreState: \(dict[CBCentralManagerRestoredStatePeripheralsKey])")
    }
    
    @objc public func centralManagerDidUpdateState(central: CBCentralManager) {
        
        if central.state == .PoweredOn {
            
            if connectedDevice != nil {
                
                connectToDevice()
                
            } else if let storedUUID = storedConnectedUUID() {
                
                if let peripheral = central.retrievePeripheralsWithIdentifiers([NSUUID(UUIDString: storedUUID)!]).first {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC))), dispatchQueue) {
                        let device = Device(peripheral: peripheral)
                        device.registerServiceManager()
                        self.connectWithDevice(device)
                    }
                }
                
            }
            
        } else if central.state == .PoweredOff {
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.connectedDevice?.serviceModelManager.resetServices()
                
                if let connectedDevice = self.connectedDevice {
                    self.delegate?.manager(self, disconnectedFromDevice: connectedDevice, retry: true)
                }
            }
            
        }
    }
    
    @objc public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let device = Device(peripheral: peripheral);
        if !foundDevices.contains(device) {
            foundDevices.append(device)
            
            // Only after adding it to the list to prevent issues reregistering the delegate.
            device.registerServiceManager()
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.delegate?.manager(self, didFindDevice: device)
            }
        }
    }
    
    @objc public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        if let connectedDevice = connectedDevice {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                // Send callback to delegate.
                self.delegate?.manager(self, connectedToDevice: connectedDevice)
                
                // Start discovering services process after connecting to peripheral.
                connectedDevice.serviceModelManager.discoverRegisteredServices()
            }
        }
    }
    
    @objc public func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didFailToConnect \(peripheral)")
    }
    
    @objc public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if peripheral.identifier.UUIDString == connectedDevice?.peripheral.identifier.UUIDString {
            let device = connectedDevice!
            device.serviceModelManager.resetServices()
            
            if disconnecting {
                // Disconnect initated by user.
                connectedDevice = nil
                disconnecting = false
            } else {
                // Send reconnect command after peripheral disconnected.
                // It will connect again when it became available.
                central.connectPeripheral(peripheral, options: nil)
            }
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.delegate?.manager(self, disconnectedFromDevice: device, retry: self.connectedDevice != nil)
            }
        }
    }
    
}


public protocol ManagerDelegate: class {
    
    /**
     Called when the `Manager` did find a peripheral and did add it to the foundDevices array.
     */
    func manager(manager: Manager, didFindDevice device: Device)
    
    /**
     Called when the `Manager` is trying to connect to device
     */
    func manager(manager: Manager, willConnectToDevice device: Device)
    
    /**
     Called when the `Manager` did connect to the device.
     */
    func manager(manager: Manager, connectedToDevice device: Device)
    
    /**
     Called when the `Manager` did disconnect from the device.
     Retry will indicate if the Manager will retry to connect when it becomes available.
     */
    func manager(manager: Manager, disconnectedFromDevice device: Device, retry: Bool)
    
}


private struct ManagerConstants {
    static let dispatchQueueLabel = "nl.e-sites.bluetooth-kit"
    static let restoreIdentifier = "nl.e-sites.bluetooth-kit.restoreIdentifier"
    static let UUIDStoreKey = "nl.e-sites.bluetooth-kit.UUID"
}


internal extension CollectionType where Generator.Element == String {
    
    func CBUUIDs() -> [CBUUID] {
        return self.map({ (UUID) -> CBUUID in
            return CBUUID(string: UUID)
        })
    }
    
}
