/**
 * Hardware Abstraction Layer (HAL) interface contracts for Bluetooth Low Energy operations.
 * Allows seamless switching between native mobile BLE drivers (CapacitorBleService)
 * and virtual test/preview simulators (MockBleService).
 */

export interface BleDevice {
  deviceId: string;
  name: string;
  rssi?: number;
  services?: string[];
}

export type DisconnectListener = (deviceId: string) => void;

export interface BleClientInterface {
  /**
   * Initializes the BLE subsystem and verifies permissions.
   */
  initialize(): Promise<void>;

  /**
   * Starts scanning for nearby BLE peripherals.
   * Calls onDeviceFound for matching devices.
   */
  startScan(onDeviceFound: (device: BleDevice) => void): Promise<void>;

  /**
   * Stops active BLE scanning.
   */
  stopScan(): Promise<void>;

  /**
   * Establishes a GATT connection to the specified peripheral.
   */
  connect(deviceId: string): Promise<void>;

  /**
   * Disconnects from the specified peripheral.
   */
  disconnect(deviceId: string): Promise<void>;

  /**
   * Performs a GATT Write Request with response to a characteristic.
   */
  writeCharacteristic(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string,
    data: Uint8Array
  ): Promise<void>;

  /**
   * Reads the current raw value of a characteristic.
   */
  readCharacteristic?(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string
  ): Promise<Uint8Array>;

  /**
   * Checks whether the specified peripheral is currently connected.
   */
  isConnected(deviceId: string): Promise<boolean>;

  /**
   * Registers a listener for peripheral disconnection events.
   */
  onDisconnect?(listener: DisconnectListener): void;

  /**
   * Removes a registered disconnection listener.
   */
  removeDisconnectListener?(listener: DisconnectListener): void;
}
