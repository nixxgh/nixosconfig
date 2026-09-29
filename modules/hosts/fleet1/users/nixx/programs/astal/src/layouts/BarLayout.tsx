import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"
import WorkspaceDots from "../components/bar/WorkspaceDots"
import Clock from "../components/bar/Clock"
import BatteryMeter from "../components/bar/BatteryMeter"
import AudioVolume from "../components/bar/AudioVolume"
import NetworkStatus from "../components/bar/NetworkStatus"
import BluetoothStatus from "../components/bar/BluetoothStatus"
import QuickToggles from "../components/bar/QuickToggles"
import NotificationBell from "../components/bar/NotificationBell"
import SystemTray from "../components/bar/SystemTray"

export default function BarLayout(gdkmonitor: Gdk.Monitor) {
  const { TOP, BOTTOM, LEFT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      namespace="bar"
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      layer={Astal.Layer.TOP}
      anchor={TOP | BOTTOM | LEFT}
      application={app}
    >
      <centerbox
        orientation={Gtk.Orientation.VERTICAL}
        widthRequest={48}
        class="py-2 px-1 bg-slate-950 border-r border-slate-800"
      >
        {/* Top: Launcher trigger & Workspaces */}
        <box
          $type="start"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={8}
          halign={Gtk.Align.CENTER}
        >
          <button
            class="launcher-btn"
            onClicked={() => execAsync("ags toggle launcher")}
          >
            <image iconName="system-search-symbolic" />
          </button>
          <WorkspaceDots />
        </box>

        {/* Center: System Tray */}
        <box
          $type="center"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={4}
          halign={Gtk.Align.CENTER}
        >
          <SystemTray />
        </box>

        {/* Bottom: Quick Toggles, Status Telemetry, Clock */}
        <box
          $type="end"
          orientation={Gtk.Orientation.VERTICAL}
          spacing={6}
          halign={Gtk.Align.CENTER}
        >
          <QuickToggles />
          <AudioVolume />
          <NetworkStatus />
          <BluetoothStatus />
          <BatteryMeter />
          <NotificationBell />
          <Clock />
        </box>
      </centerbox>
    </window>
  )
}
