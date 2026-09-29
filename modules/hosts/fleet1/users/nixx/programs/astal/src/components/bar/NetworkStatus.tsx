import { createBinding, For, With } from "ags"
import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import AstalNetwork from "gi://AstalNetwork"

export default function NetworkStatus() {
  const network = AstalNetwork.get_default()
  if (!network) return <box />

  const wifi = createBinding(network, "wifi")

  const deduplicated = (wifiObj: AstalNetwork.Wifi) => (arr: Array<AstalNetwork.AccessPoint>) => {
    if (!arr) return []
    const active = wifiObj.ssid
    const seen = new Set<string>()
    return [...arr]
      .filter((ap) => !!ap.ssid)
      .sort((a, b) => {
        if (active && a.ssid === active && b.ssid !== active) return -1
        if (active && b.ssid === active && a.ssid !== active) return 1
        return b.strength - a.strength
      })
      .filter((ap) => {
        if (seen.has(ap.ssid)) return false
        seen.add(ap.ssid)
        return true
      })
      .slice(0, 8)
  }

  async function connect(ap: AstalNetwork.AccessPoint) {
    try {
      await execAsync(`nmcli d wifi connect "${ap.ssid}"`)
    } catch (error) {
      console.error("Wi-Fi connection error:", error)
    }
  }

  async function toggleWifi() {
    try {
      await execAsync("nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on")
    } catch (error) {
      console.error("Failed to toggle Wi-Fi:", error)
    }
  }

  return (
    <box visible={wifi(Boolean)} halign={Gtk.Align.CENTER}>
      <With value={wifi}>
        {(wifi) =>
          wifi && (
            <menubutton class="status-btn" halign={Gtk.Align.CENTER}>
              <image halign={Gtk.Align.CENTER} iconName={createBinding(wifi, "iconName")} />
              <popover autohide={false} position={Gtk.PositionType.TOP}>
                <box orientation={Gtk.Orientation.VERTICAL} spacing={8} widthRequest={240}>
                  {/* Header */}
                  <centerbox class="pb-2 border-b border-slate-800">
                    <box $type="start">
                      <label
                        class="text-xs font-bold text-white"
                        label={createBinding(wifi, "ssid")((s) => (s ? s : "Disconnected"))}
                      />
                    </box>
                    <box $type="center" />
                    <box $type="end">
                      <button class="p-1 rounded text-xs text-emerald-400 hover:bg-slate-800" onClicked={toggleWifi}>
                        <label label="Toggle" />
                      </button>
                    </box>
                  </centerbox>

                  {/* Access points list */}
                  <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                    <For each={createBinding(wifi, "accessPoints")(deduplicated(wifi))}>
                      {(ap: AstalNetwork.AccessPoint) => (
                        <button
                          class="p-1.5 rounded hover:bg-slate-800"
                          onClicked={() => connect(ap)}
                        >
                          <centerbox>
                            <box $type="start" spacing={6}>
                              <image
                                class={createBinding(wifi, "ssid")((activeSsid) =>
                                  activeSsid === ap.ssid ? "text-emerald-400" : "text-white"
                                )}
                                iconName={createBinding(ap, "iconName")}
                              />
                              <label
                                class={createBinding(wifi, "ssid")((activeSsid) =>
                                  activeSsid === ap.ssid ? "text-xs font-bold text-emerald-400" : "text-xs text-white"
                                )}
                                label={createBinding(ap, "ssid")}
                              />
                            </box>
                            <box $type="center" />
                            <box $type="end">
                              <label
                                class="text-xs font-bold text-emerald-400"
                                visible={createBinding(wifi, "ssid")((activeSsid) => activeSsid === ap.ssid)}
                                label="Connected"
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
      </With>
    </box>
  )
}
