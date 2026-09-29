import { createBinding, For } from "ags"
import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import AstalBluetooth from "gi://AstalBluetooth"

export default function BluetoothStatus() {
  const bt = AstalBluetooth.get_default()
  if (!bt) return <box />

  const isPowered = createBinding(bt, "isPowered")
  const isConnected = createBinding(bt, "isConnected")
  const devices = createBinding(bt, "devices")

  async function togglePower() {
    try {
      await execAsync("bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on")
    } catch (err) {
      console.error("Failed to toggle bluetooth power:", err)
    }
  }

  async function toggleDevice(device: AstalBluetooth.Device) {
    try {
      if (device.connected) {
        await execAsync(`bluetoothctl disconnect ${device.address}`)
      } else {
        await execAsync(`bluetoothctl connect ${device.address}`)
      }
    } catch (err) {
      console.error("Failed to toggle device:", err)
    }
  }

  return (
    <menubutton class="status-btn" halign={Gtk.Align.CENTER}>
      <image
        halign={Gtk.Align.CENTER}
        class={isConnected((c) => (c ? "text-emerald-400" : "text-white"))}
        iconName="bluetooth-active-symbolic"
      />
      <popover autohide={false} position={Gtk.PositionType.TOP}>
        <box orientation={Gtk.Orientation.VERTICAL} spacing={8} widthRequest={220}>
          {/* Header */}
          <centerbox class="pb-2 border-b border-slate-800">
            <box $type="start">
              <label
                class="text-xs font-bold text-white"
                label={isPowered((p) => (p ? "Bluetooth ON" : "Bluetooth OFF"))}
              />
            </box>
            <box $type="center" />
            <box $type="end">
              <button
                class="p-1 rounded text-xs text-emerald-400 hover:bg-slate-800"
                onClicked={togglePower}
              >
                <label label="Toggle" />
              </button>
            </box>
          </centerbox>

          {/* Device List */}
          <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
            <For each={devices}>
              {(device: AstalBluetooth.Device) => (
                <button
                  class="p-1.5 rounded hover:bg-slate-800"
                  onClicked={() => toggleDevice(device)}
                >
                  <centerbox>
                    <box $type="start" spacing={6}>
                      <image iconName={createBinding(device, "icon")} />
                      <label
                        class="text-xs text-white"
                        label={createBinding(device, "name")((n) => n || device.address)}
                      />
                    </box>
                    <box $type="center" />
                    <box $type="end">
                      <label
                        class={createBinding(device, "connected")((c) =>
                          c ? "text-xs font-bold text-emerald-400" : "text-xs text-slate-400"
                        )}
                        label={createBinding(device, "connected")((c) => (c ? "Connected" : "Connect"))}
                      />
                    </box>
                  </centerbox>
                </button>
              )}
            </For>
          </box>
        </box>
      </popover>
    </menubutton>
  )
}
