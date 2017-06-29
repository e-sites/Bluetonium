//
//  Bluetonium_iOS_Tests.swift
//  Bluetonium-iOS_Tests
//
//  Created by Bas van Kuijck on 27/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

import XCTest
import CoreBluetooth
@testable import Bluetonium

class BatteryServiceModel: ServiceModel {

    enum Characteristic : String {
        case batteryLevel = "2A19"
        case batteryName = "34E196E3-02BB-486D-A080-AD14C1AF95A3"
    }

    var batteryLevel: UInt8 = 0
    var batteryName:String = ""

    override var serviceUUID:String {
        return "180F"
    }

    override func mapping(_ map: Map) {
        batteryLevel <- map[Characteristic.batteryLevel.rawValue]
        batteryName  <- map[Characteristic.batteryName.rawValue]
    }
}

class Bluetonium_iOS_Tests: XCTestCase {

    enum TestCase {
        case none
        case deviceConnect
        case readDevice
        case writeDevice
    }

    let manager = Manager()
    var testCase:TestCase = .none

    fileprivate let mockBatteryLevel:UInt8 = 80
    fileprivate let mockDeviceName = "Bluetonium Mocking Device"
    fileprivate let mockBatteryName = "Bluetonium battery"
    fileprivate let mockDeviceIdentifier = UUID(uuidString: "C218FE6F-F079-46A3-96FF-160AB0342A46")!

    fileprivate let batteryServiceModel = BatteryServiceModel()

    let peripheralMock = CBPeripheralMock()
    let batteryLevelCharacteristicMock = CBCharacteristicMock()
    let batteryNameCharacteristicMock = CBCharacteristicMock()
    let batteryServiceCharacteristicServiceMock = CBServiceMock()

    fileprivate var _expectation:XCTestExpectation?

    override func setUp() {
        super.setUp()
        batteryLevelCharacteristicMock.uuid = CBUUID(string: BatteryServiceModel.Characteristic.batteryLevel.rawValue)
        batteryNameCharacteristicMock.uuid = CBUUID(string: BatteryServiceModel.Characteristic.batteryName.rawValue)

        batteryServiceCharacteristicServiceMock.uuid = CBUUID(string: batteryServiceModel.serviceUUID)
        batteryLevelCharacteristicMock.service = batteryServiceCharacteristicServiceMock.service
        batteryNameCharacteristicMock.service = batteryServiceCharacteristicServiceMock.service
        manager.delegate = self
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDeviceConnect() {
        _runTest(case: .deviceConnect)
    }

    func testReadDevice() {
        _runTest(case: .readDevice)
    }

    func testWriteDevice() {
        _runTest(case: .writeDevice)
    }
}

extension Bluetonium_iOS_Tests {

    fileprivate func _runTest(`case` aCase: TestCase) {
        testCase = aCase
        _expectation = expectation(description: "mock")
        manager.startScanForDevices()
        peripheralMock.name = mockDeviceName
        peripheralMock.identifier = mockDeviceIdentifier
        let device = Device(peripheral: peripheralMock.peripheral)

        manager.delegate?.manager(manager, didFindDevice: device)
        waitForExpectations(timeout: 2, handler: nil)
    }


    fileprivate func _disconnect(device: Device) {
        manager.disconnectFromDevice()
        peripheralMock.state = .disconnecting
        if let centralManager = manager.centralManager {
            manager.centralManager(centralManager, didDisconnectPeripheral: device.peripheral, error: nil)
        } else {
            XCTAssert(false, "Manager is missing a centralManager")
        }
    }
}

extension Bluetonium_iOS_Tests : ManagerDelegate {

    func manager(_ manager: Manager, didFindDevice device: Device) {

        XCTAssertEqual(device.peripheral.state, CBPeripheralState.disconnected)
        XCTAssertEqual(device.peripheral.name, mockDeviceName)
        XCTAssertEqual(device.peripheral.identifier, mockDeviceIdentifier)
        XCTAssertEqual(device.serviceModelManager.peripheral?.identifier, mockDeviceIdentifier)

        manager.connect(with: device)
        peripheralMock.state = .connecting
    }

    func manager(_ manager: Manager, willConnectToDevice device: Device) {
        XCTAssertEqual(device.peripheral.state, CBPeripheralState.connecting)
        peripheralMock.state = .connected
        device.register(serviceModel: batteryServiceModel)
        manager.delegate?.manager(manager, connectedToDevice: device)
        XCTAssert(device.registedServiceModels.contains(batteryServiceModel), "device.registedServiceModels does not contain `batteryServiceModel`")
    }

    func manager(_ manager: Manager, connectedToDevice device: Device) {
        XCTAssertEqual(device.peripheral.state, CBPeripheralState.connected)
        switch (testCase) {
        case .deviceConnect:
            _disconnect(device: device)

        case .readDevice:
            batteryServiceModel.readValue(withUUID: BatteryServiceModel.Characteristic.batteryLevel.rawValue) { value in
                XCTAssert(value is UInt8, "value is not a UInt8")
                XCTAssertEqual(value as! UInt8, self.mockBatteryLevel)
                self._disconnect(device: device)
            }

            let input = mockBatteryLevel
            var value = input
            let data = withUnsafePointer(to: &value) {
                Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: input))
            }
            batteryLevelCharacteristicMock.value = data

            batteryServiceModel.serviceModelManager?.peripheral(device.peripheral, didUpdateValueFor: batteryLevelCharacteristicMock.characteristic, error: nil)
        case .writeDevice:
            batteryServiceModel.batteryName = mockBatteryName
            batteryServiceModel.writeValue(withUUID: BatteryServiceModel.Characteristic.batteryName.rawValue)
            self._disconnect(device: device)


        default:
            break
        }
    }

    func manager(_ manager: Manager, disconnectedFromDevice device: Device, willRetry retry: Bool) {
        XCTAssertEqual(device.peripheral.state, CBPeripheralState.disconnecting)
        peripheralMock.state = .disconnected
        XCTAssertEqual(device.peripheral.state, CBPeripheralState.disconnected)
        _expectation?.fulfill()
    }
}
