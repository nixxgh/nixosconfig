import AstalBluetooth from "gi://AstalBluetooth"

export function getBluetooth() {
  return AstalBluetooth.get_default()
}
