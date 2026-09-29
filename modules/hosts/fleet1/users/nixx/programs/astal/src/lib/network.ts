import AstalNetwork from "gi://AstalNetwork"

export function getNetwork() {
  return AstalNetwork.get_default()
}
