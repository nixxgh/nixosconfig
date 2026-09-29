import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import GLib from "gi://GLib"
import { getAudio, setVolume, toggleMute } from "../lib/wireplumber"
import { formatPercentage } from "../utils/formatters"

const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

export default function DeckLayout() {
  let win: Astal.Window

  const now = GLib.DateTime.new_now_local()
  const initialTime = now.format("%H:%M:%S") || "--:--:--"
  const initialDate = now.format("%A, %B %d, %Y") || ""

  // Telemetry Pollers
  const clockTime = createPoll(initialTime, 1000, () => {
    return GLib.DateTime.new_now_local().format("%H:%M:%S") || "--:--:--"
  })

  const clockDate = createPoll(initialDate, 60000, () => {
    return GLib.DateTime.new_now_local().format("%A, %B %d, %Y") || ""
  })

  const cpuData = createPoll({ load: "0.00, 0.00, 0.00" }, 3000, async () => {
    try {
      const raw = await execAsync("cat /proc/loadavg")
      const parts = raw.trim().split(" ")
      return { load: `${parts[0]}, ${parts[1]}, ${parts[2]}` }
    } catch {
      return { load: "0.00, 0.00, 0.00" }
    }
  })

  const memData = createPoll({ label: "Loading..." }, 3000, async () => {
    try {
      const out = await execAsync("free -m")
      const lines = out.split("\n")
      const memLine = lines.find((l) => l.startsWith("Mem:"))
      if (memLine) {
        const parts = memLine.trim().split(/\s+/)
        const total = parseFloat(parts[1]) / 1024
        const used = parseFloat(parts[2]) / 1024
        const pct = Math.round((parseFloat(parts[2]) * 100) / parseFloat(parts[1]))
        return { label: `${used.toFixed(1)} GB / ${total.toFixed(1)} GB (${pct}%)` }
      }
      return { label: "N/A" }
    } catch {
      return { label: "N/A" }
    }
  })

  const swapData = createPoll({ label: "0 GB / 0 GB (0%)" }, 5000, async () => {
    try {
      const out = await execAsync("free -m")
      const lines = out.split("\n")
      const swapLine = lines.find((l) => l.startsWith("Swap:"))
      if (swapLine) {
        const parts = swapLine.trim().split(/\s+/)
        const total = parseFloat(parts[1]) / 1024
        const used = parseFloat(parts[2]) / 1024
        if (total > 0) {
          const pct = Math.round((parseFloat(parts[2]) * 100) / parseFloat(parts[1]))
          return { label: `${used.toFixed(1)} GB / ${total.toFixed(1)} GB (${pct}%)` }
        }
        return { label: "0 GB / 0 GB (0%)" }
      }
      return { label: "0 GB / 0 GB (0%)" }
    } catch {
      return { label: "0 GB / 0 GB (0%)" }
    }
  })

  const diskData = createPoll({ label: "Loading..." }, 15000, async () => {
    try {
      const out = await execAsync("df -h /")
      const lines = out.trim().split("\n")
      if (lines.length >= 2) {
        const parts = lines[1].trim().split(/\s+/)
        return { label: `${parts[2]} / ${parts[1]} (${parts[4]})` }
      }
      return { label: "N/A" }
    } catch {
      return { label: "N/A" }
    }
  })

  const uptimeData = createPoll({ label: "..." }, 10000, async () => {
    try {
      const raw = await execAsync("cat /proc/uptime")
      const sec = parseFloat(raw.trim().split(" ")[0])
      const h = Math.floor(sec / 3600)
      const m = Math.floor((sec % 3600) / 60)
      return { label: `${h}h ${m}m` }
    } catch {
      return { label: "N/A" }
    }
  })

  const batteryData = createPoll({ cap: 100, charging: false }, 5000, async () => {
    try {
      const capStr = await execAsync("cat /sys/class/power_supply/BAT0/capacity")
      const statusStr = await execAsync("cat /sys/class/power_supply/BAT0/status")
      return {
        cap: parseInt(capStr.trim(), 10) || 100,
        charging: statusStr.trim().toLowerCase() === "charging",
      }
    } catch {
      return { cap: 100, charging: false }
    }
  })

  const ipData = createPoll({ ip: "..." }, 10000, async () => {
    try {
      const raw = await execAsync("hostname -I")
      const first = raw.trim().split(/\s+/)[0]
      return { ip: first || "Disconnected" }
    } catch {
      return { ip: "N/A" }
    }
  })

  const wifiData = createPoll({ ssid: "Scanning..." }, 5000, async () => {
    try {
      const raw = await execAsync("nmcli -t -f active,ssid dev wifi")
      const line = raw.split("\n").find((l) => l.startsWith("yes:"))
      return { ssid: line ? line.replace("yes:", "") : "Disconnected" }
    } catch {
      return { ssid: "Disconnected" }
    }
  })

  const btData = createPoll({ status: "Standby" }, 5000, async () => {
    try {
      const raw = await execAsync("bluetoothctl show")
      if (!raw.includes("Powered: yes")) return { status: "Powered Off" }
      const info = await execAsync("bluetoothctl info")
      const match = info.match(/Name:\s+(.*)/)
      return { status: match ? `Connected: ${match[1]}` : "Standby" }
    } catch {
      return { status: "Standby" }
    }
  })

  const audioSinkData = createPoll({ desc: "Default Audio Sink" }, 5000, async () => {
    try {
      const out = await execAsync("wpctl inspect @DEFAULT_AUDIO_SINK@")
      const match = out.match(/node\.description = "(.*)"/)
      return { desc: match ? match[1] : "Default Audio Sink" }
    } catch {
      return { desc: "Default Audio Sink" }
    }
  })

  // Audio bindings from WirePlumber
  const speaker = getAudio()
  const volume = speaker ? createBinding(speaker, "volume") : null
  const isMuted = speaker ? createBinding(speaker, "mute") : null

  function onKey(_e: Gtk.EventControllerKey, keyval: number) {
    if (keyval === Gdk.KEY_Escape) {
      if (win) win.visible = false
      return true
    }
    return false
  }

  function launchAndDismiss(cmd: string) {
    if (win) win.visible = false
    execAsync(cmd).catch(console.error)
  }

  return (
    <window
      $={(ref) => (win = ref)}
      name="deck"
      namespace="deck"
      class="Deck"
      application={app}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      marginTop={5}
      marginBottom={5}
      marginLeft={5}
      marginRight={5}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      visible={false}
    >
      <Gtk.EventControllerKey onKeyPressed={onKey} />

      <box
        orientation={Gtk.Orientation.VERTICAL}
        vexpand
        hexpand
        class="deck-surface"
        spacing={14}
      >
        {/* Top Header Bar */}
        <centerbox class="pb-3 border-b border-teal-500/30">
          {/* Header Left */}
          <box $type="start" spacing={12} valign={Gtk.Align.CENTER}>
            <box class="deck-header-badge" spacing={6} valign={Gtk.Align.CENTER}>
              <label class="text-xs font-bold text-teal-300" label="CYBER DECK // MASTER HUD" />
            </box>
            <label class="text-xs font-semibold text-emerald-400" label="● ONLINE" />
            <label class="text-xs text-slate-200" label="Host: laptop" />
          </box>

          {/* Header Center */}
          <box $type="center" spacing={16} valign={Gtk.Align.CENTER}>
            <label
              class="text-xs text-slate-200"
              label={uptimeData(({ label }) => `Uptime: ${label || "N/A"}`)}
            />
            <label class="text-xs text-teal-300" label="NixOS // x86_64-linux" />
          </box>

          {/* Header Right */}
          <box $type="end" spacing={12} valign={Gtk.Align.CENTER}>
            <box spacing={8} valign={Gtk.Align.CENTER}>
              <label class="text-xs text-slate-200" label={clockDate} />
              <label class="text-sm font-bold text-white" label={clockTime} />
            </box>
            <button
              class="deck-action-btn"
              onClicked={() => {
                if (win) win.visible = false
              }}
            >
              <label class="text-xs font-bold" label="ESC ✕" />
            </button>
          </box>
        </centerbox>

        {/* Main Dashboard 4-Column Grid */}
        <box orientation={Gtk.Orientation.HORIZONTAL} vexpand spacing={14} homogeneous>
          {/* Column 1: System Telemetry */}
          <box orientation={Gtk.Orientation.VERTICAL} class="deck-card" spacing={12}>
            <box spacing={8} class="pb-2 border-b border-teal-500/20">
              <image iconName="utilities-system-monitor-symbolic" />
              <label class="text-sm font-bold text-teal-300" label="System Telemetry" />
            </box>

            <box orientation={Gtk.Orientation.VERTICAL} spacing={10} vexpand>
              {/* CPU Load */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                <label class="text-xs text-slate-200" halign={Gtk.Align.START} label="CPU Load Average (1m, 5m, 15m)" />
                <label
                  class="text-sm font-semibold text-white"
                  halign={Gtk.Align.START}
                  label={cpuData(({ load }) => load || "0.00, 0.00, 0.00")}
                />
              </box>

              {/* Memory */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                <label class="text-xs text-slate-200" halign={Gtk.Align.START} label="Memory Usage (RAM)" />
                <label
                  class="text-sm font-semibold text-white"
                  halign={Gtk.Align.START}
                  label={memData(({ label }) => label || "N/A")}
                />
              </box>

              {/* Swap */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                <label class="text-xs text-slate-200" halign={Gtk.Align.START} label="Swap Allocation" />
                <label
                  class="text-sm font-semibold text-white"
                  halign={Gtk.Align.START}
                  label={swapData(({ label }) => label || "0 GB / 0 GB (0%)")}
                />
              </box>

              {/* Disk */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                <label class="text-xs text-slate-200" halign={Gtk.Align.START} label="Primary Storage (Root /)" />
                <label
                  class="text-sm font-semibold text-white"
                  halign={Gtk.Align.START}
                  label={diskData(({ label }) => label || "N/A")}
                />
              </box>

              {/* Battery */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                <label class="text-xs text-slate-200" halign={Gtk.Align.START} label="Battery Status" />
                <box spacing={6}>
                  <image
                    iconName={batteryData(({ cap, charging }) => {
                      const suffix = charging ? "-charging" : ""
                      if (cap >= 80) return `battery-full${suffix}-symbolic`
                      if (cap >= 30) return `battery-good${suffix}-symbolic`
                      return `battery-empty${suffix}-symbolic`
                    })}
                  />
                  <label
                    class="text-sm font-semibold text-white"
                    label={batteryData(({ cap, charging }) => `${cap}% (${charging ? "Charging" : "Discharging"})`)}
                  />
                </box>
              </box>
            </box>
          </box>

          {/* Column 2: Audio & Media HUD */}
          <box orientation={Gtk.Orientation.VERTICAL} class="deck-card" spacing={12}>
            <box spacing={8} class="pb-2 border-b border-teal-500/20">
              <image iconName="audio-volume-high-symbolic" />
              <label class="text-sm font-bold text-teal-300" label="Audio & Media" />
            </box>

            <box orientation={Gtk.Orientation.VERTICAL} spacing={12} vexpand>
              {/* Volume Level */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={6}>
                <centerbox>
                  <label $type="start" class="text-xs text-slate-200" label="Master Volume" />
                  <box $type="center" />
                  <label
                    $type="end"
                    class="text-xs font-bold text-emerald-400"
                    label={volume ? volume((v) => (typeof v === "number" ? formatPercentage(v) : "0%")) : "0%"}
                  />
                </centerbox>
                {volume && (
                  <slider
                    value={volume}
                    onChangeValue={({ value }) => setVolume(value)}
                  />
                )}
              </box>

              {/* Audio Controls */}
              <box spacing={8}>
                <button
                  class="deck-action-btn"
                  hexpand
                  onClicked={() => toggleMute()}
                >
                  <box spacing={6} halign={Gtk.Align.CENTER}>
                    <image iconName="audio-volume-muted-symbolic" />
                    <label
                      label={isMuted ? isMuted((m) => (m ? "Unmute" : "Mute")) : "Mute"}
                      class="text-xs font-semibold"
                    />
                  </box>
                </button>
              </box>

              {/* Audio Routing Info */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={4} class="p-3 bg-slate-900/60 rounded-lg border border-teal-500/20">
                <label class="text-xs font-semibold text-teal-300" halign={Gtk.Align.START} label="WirePlumber Sink" />
                <label
                  class="text-xs text-slate-200"
                  halign={Gtk.Align.START}
                  label={audioSinkData(({ desc }) => desc || "Default Audio Sink")}
                />
              </box>
            </box>
          </box>

          {/* Column 3: Connectivity */}
          <box orientation={Gtk.Orientation.VERTICAL} class="deck-card" spacing={12}>
            <box spacing={8} class="pb-2 border-b border-teal-500/20">
              <image iconName="network-wireless-symbolic" />
              <label class="text-sm font-bold text-teal-300" label="Connectivity" />
            </box>

            <box orientation={Gtk.Orientation.VERTICAL} spacing={12} vexpand>
              {/* Wi-Fi Info */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                <label class="text-xs text-slate-200" halign={Gtk.Align.START} label="Wi-Fi Network" />
                <box spacing={6}>
                  <image iconName="network-wireless-signal-excellent-symbolic" />
                  <label
                    class="text-sm font-semibold text-white"
                    label={wifiData(({ ssid }) => ssid || "Disconnected")}
                  />
                </box>
              </box>

              {/* IPv4 Address */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
                <label class="text-xs text-slate-200" halign={Gtk.Align.START} label="Local IP Address" />
                <label
                  class="text-sm font-semibold text-white"
                  halign={Gtk.Align.START}
                  label={ipData(({ ip }) => ip || "Disconnected")}
                />
              </box>

              {/* Bluetooth Status */}
              <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                <label class="text-xs text-slate-200" halign={Gtk.Align.START} label="Bluetooth Subsystem" />
                <box spacing={6}>
                  <image iconName="bluetooth-active-symbolic" />
                  <label
                    class="text-sm font-semibold text-white"
                    label={btData(({ status }) => status || "Standby")}
                  />
                </box>
              </box>
            </box>
          </box>

          {/* Column 4: Command Console & Quick Actions */}
          <box orientation={Gtk.Orientation.VERTICAL} class="deck-card" spacing={12}>
            <box spacing={8} class="pb-2 border-b border-teal-500/20">
              <image iconName="utilities-terminal-symbolic" />
              <label class="text-sm font-bold text-teal-300" label="Command Console" />
            </box>

            <box orientation={Gtk.Orientation.VERTICAL} spacing={8} vexpand>
              <button
                class="deck-action-btn"
                onClicked={() => launchAndDismiss("alacritty")}
              >
                <box spacing={8} halign={Gtk.Align.START}>
                  <image iconName="utilities-terminal-symbolic" />
                  <label class="text-xs font-semibold text-white" label="Alacritty Terminal" />
                </box>
              </button>

              <button
                class="deck-action-btn"
                onClicked={() => launchAndDismiss("zen")}
              >
                <box spacing={8} halign={Gtk.Align.START}>
                  <image iconName="web-browser-symbolic" />
                  <label class="text-xs font-semibold text-white" label="Zen Web Browser" />
                </box>
              </button>

              <button
                class="deck-action-btn"
                onClicked={() => launchAndDismiss("alacritty -e yazi")}
              >
                <box spacing={8} halign={Gtk.Align.START}>
                  <image iconName="system-file-manager-symbolic" />
                  <label class="text-xs font-semibold text-white" label="Yazi File Manager" />
                </box>
              </button>

              <button
                class="deck-action-btn"
                onClicked={() => launchAndDismiss("alacritty -e btop")}
              >
                <box spacing={8} halign={Gtk.Align.START}>
                  <image iconName="utilities-system-monitor-symbolic" />
                  <label class="text-xs font-semibold text-white" label="Btop System Monitor" />
                </box>
              </button>

              <box vexpand />

              {/* Power Controls */}
              <box spacing={6}>
                <button
                  class="deck-action-btn"
                  hexpand
                  onClicked={() => launchAndDismiss("loginctl lock-session")}
                >
                  <box spacing={4} halign={Gtk.Align.CENTER}>
                    <image iconName="system-lock-screen-symbolic" />
                    <label class="text-xs font-semibold" label="Lock" />
                  </box>
                </button>

                <button
                  class="deck-action-btn"
                  hexpand
                  onClicked={() => launchAndDismiss("systemctl suspend")}
                >
                  <box spacing={4} halign={Gtk.Align.CENTER}>
                    <image iconName="media-playback-pause-symbolic" />
                    <label class="text-xs font-semibold" label="Sleep" />
                  </box>
                </button>

                <button
                  class="deck-action-btn danger"
                  hexpand
                  onClicked={() => launchAndDismiss("systemctl reboot")}
                >
                  <box spacing={4} halign={Gtk.Align.CENTER}>
                    <image iconName="system-reboot-symbolic" />
                    <label class="text-xs font-semibold" label="Reboot" />
                  </box>
                </button>
              </box>
            </box>
          </box>
        </box>

        {/* Footer Info */}
        <centerbox class="pt-2 border-t border-teal-500/20">
          <box $type="start" spacing={12}>
            <label class="text-xs text-slate-200" label="[Mod + B] Toggle Cyber Deck" />
            <label class="text-xs text-slate-200" label="[ESC] Dismiss" />
          </box>
          <box $type="center" />
          <box $type="end">
            <label class="text-xs font-semibold text-teal-300" label="Astal Shell // Niri Wayland Compositor" />
          </box>
        </centerbox>
      </box>
    </window>
  )
}
