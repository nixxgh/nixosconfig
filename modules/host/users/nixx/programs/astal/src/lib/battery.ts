import AstalBattery from "gi://AstalBattery"

export function getBattery() {
  return AstalBattery.get_default()
}
