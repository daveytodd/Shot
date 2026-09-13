import CoreBluetooth
import Foundation

@MainActor final class DJIGimbalManager: NSObject, ObservableObject {
    @Published private(set) var isPaired = false
    @Published private(set) var deviceName: String?
    @Published private(set) var isScanning = false
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    private let serviceUUID = CBUUID(string: "0000FE50-0000-1000-8000-00805F9B34FB")
    override init() { super.init(); central = CBCentralManager(delegate: self, queue: nil) }
    func scan() { guard central.state == .poweredOn else { return }; isScanning = true; central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]) }
    func disconnect() { if let peripheral { central.cancelPeripheralConnection(peripheral) } }
    func advanceSweep() async { guard let writeCharacteristic else { return }; let packet = GimbalPacket.waypoint(pan: 0, tilt: 0); peripheral?.writeValue(packet, for: writeCharacteristic, type: .withoutResponse) }
    private func handle(_ data: Data) { if data.contains(0x01) { NotificationCenter.default.post(name: .shotHardwareShutter, object: nil) } }
}
extension DJIGimbalManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) { if central.state == .poweredOn { scan() } }
    func centralManager(_ central: CBCentralManager, didDiscover p: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) { guard p.name?.localizedCaseInsensitiveContains("DJI") == true || p.name?.localizedCaseInsensitiveContains("Osmo") == true else { return }; self.peripheral = p; deviceName = p.name; isScanning = false; central.stopScan(); p.delegate = self; central.connect(p) }
    func centralManager(_ central: CBCentralManager, didConnect p: CBPeripheral) { isPaired = true; p.discoverServices(nil) }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) { isPaired = false; writeCharacteristic = nil; notifyCharacteristic = nil }
    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) { p.services?.forEach { p.discoverCharacteristics(nil, for: $0) } }
    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) { service.characteristics?.forEach { c in if c.properties.contains(.writeWithoutResponse) { writeCharacteristic = c }; if c.properties.contains(.notify) { notifyCharacteristic = c; p.setNotifyValue(true, for: c) } } }
    func peripheral(_ p: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) { if let data = characteristic.value { handle(data) } }
}
enum GimbalPacket { static func waypoint(pan: Int16, tilt: Int16) -> Data { var d = Data([0x55, 0x0A, 0x01]); withUnsafeBytes(of: pan.bigEndian) { d.append(contentsOf: $0) }; withUnsafeBytes(of: tilt.bigEndian) { d.append(contentsOf: $0) }; d.append(crc8(d)); return d }; private static func crc8(_ data: Data) -> UInt8 { data.reduce(0) { $0 ^ $1 } } }
extension Notification.Name { static let shotHardwareShutter = Notification.Name("ShotHardwareShutter") }
