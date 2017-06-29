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
        batteryName  <- (map[Characteristic.batteryName.rawValue], StringDataTransformer())
    }
}

class Bluetonium_iOS_Tests: XCTestCase {

    enum TestCase {
        case none
        case deviceConnect
        case readDevice
        case writeDevice
    }

    lazy var manager:Manager = {
        return Manager(centralManager: self.centralManagerMock.centralManager)
    }()

    let centralManagerMock = CBCentralManagerMock()

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
        batteryServiceCharacteristicServiceMock.characteristics = [ batteryLevelCharacteristicMock.characteristic, batteryNameCharacteristicMock.characteristic ]
        batteryLevelCharacteristicMock.service = batteryServiceCharacteristicServiceMock.service
        batteryNameCharacteristicMock.service = batteryServiceCharacteristicServiceMock.service

        peripheralMock.name = mockDeviceName
        peripheralMock.identifier = mockDeviceIdentifier
        peripheralMock.services = [ batteryServiceCharacteristicServiceMock.service ]

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

    func testDataTransformerData() {
        let dataTransformer = DataDataTransformer()

        let testString = "test"
        let data = testString.data(using: .utf8)
        let transformToData = dataTransformer.transform(dataToValue: data) as? Data
        XCTAssertEqual(transformToData?.count, data?.count)

        let transformFromData = dataTransformer.transform(valueToData: data)
        XCTAssertEqual(transformFromData.count, data?.count)
        XCTAssertEqual(dataTransformer.transform(valueToData: nil).count, 0)
        XCTAssertEqual((dataTransformer.transform(dataToValue: nil) as! Data).count, 0)

    }

    func testDataTransformerString() {
        let dataTransformer = StringDataTransformer()

        let testString = "test"
        let data = testString.data(using: .utf8)
        let transformToString = dataTransformer.transform(dataToValue: data) as? String
        XCTAssertEqual(transformToString, testString)

        let transformToData = dataTransformer.transform(valueToData: testString)
        XCTAssertEqual(transformToData.count, data?.count)
        XCTAssertEqual(dataTransformer.transform(valueToData: nil).count, 0)
        XCTAssertEqual(dataTransformer.transform(dataToValue: nil) as! String, "")

    }

    func testDataTransformerUInt() {
        let dataTransformer = UIntDataTransformer<UInt8>()

        let testUInt:UInt8 = 9
        let data = testUInt.toData()
        let transformToUInt8 = dataTransformer.transform(dataToValue: data) as? UInt8
        XCTAssertEqual(transformToUInt8, testUInt)

        let transformToData = dataTransformer.transform(valueToData: testUInt)
        XCTAssertEqual(transformToData.count, data.count)
        XCTAssertEqual(dataTransformer.transform(valueToData: nil).count, 0)
        XCTAssertEqual(dataTransformer.transform(dataToValue: nil) as! UInt8, 0)
    }
}

extension Bluetonium_iOS_Tests {

    fileprivate func _runTest(`case` aCase: TestCase) {
        testCase = aCase
        _expectation = expectation(description: "mock")
        manager.startScanForDevices()
        XCTAssertEqual(manager.scanning, true)
        centralManagerMock.state = .poweredOff
        manager.centralManagerDidUpdateState(centralManagerMock.centralManager)
        centralManagerMock.state = .poweredOn
        manager.centralManagerDidUpdateState(centralManagerMock.centralManager)

        manager.centralManager(centralManagerMock.centralManager, didDiscover: peripheralMock.peripheral, advertisementData: [:], rssi: 0)
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

extension UInt8 {
    func toData() -> Data {
        var value = self
        let data = withUnsafePointer(to: &value) {
            Data(bytes: UnsafePointer($0), count: MemoryLayout.size(ofValue: self))
        }
        return data
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
        manager.centralManager(centralManagerMock.centralManager, didConnect: device.peripheral)

//        manager.delegate?.manager(manager, connectedToDevice: device)

        device.serviceModelManager.peripheral(device.peripheral, didDiscoverServices: nil)
        device.serviceModelManager.peripheral(device.peripheral, didDiscoverCharacteristicsFor: batteryServiceCharacteristicServiceMock.service, error: nil)
        
        XCTAssert(device.registedServiceModels.contains(batteryServiceModel), "device.registedServiceModels does not contain `batteryServiceModel`")
    }

    func manager(_ manager: Manager, connectedToDevice device: Device) {
        manager.stopScanForDevices()
        XCTAssertEqual(manager.scanning, false)
        XCTAssert(batteryServiceModel.serviceModelManager?.characteristicAvailable(BatteryServiceModel.Characteristic.batteryLevel.rawValue, serviceUUID: batteryServiceModel.serviceUUID) == true)

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


            let data = mockBatteryLevel.toData()
            batteryLevelCharacteristicMock.value = data

            batteryServiceModel.serviceModelManager?.peripheral(device.peripheral, didUpdateValueFor: batteryLevelCharacteristicMock.characteristic, error: nil)
        case .writeDevice:
            batteryServiceModel.batteryName = mockBatteryName
            batteryServiceModel.writeValue(withUUID: BatteryServiceModel.Characteristic.batteryName.rawValue)
            device.serviceModelManager.peripheral(device.peripheral, didWriteValueFor: batteryNameCharacteristicMock.characteristic, error: nil)
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
