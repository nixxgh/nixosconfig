import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import AstalNotifd from "gi://AstalNotifd"

export default function NotificationBell() {
  const notifd = AstalNotifd.get_default()
  if (!notifd) return <box />

  const count = createBinding(notifd, "notifications")((ns) => ns.length)

  return (
    <button
      class="status-btn"
      halign={Gtk.Align.CENTER}
      onClicked={() => execAsync("ags toggle notifications")}
    >
      <box spacing={2} halign={Gtk.Align.CENTER}>
        <image
          class={count((c) => (c > 0 ? "bell-active" : "bell-inactive"))}
          iconName="preferences-system-notifications-symbolic"
        />
        <label
          visible={count((c) => c > 0)}
          class="text-xs font-bold text-emerald-400"
          label={count((c) => String(c))}
        />
      </box>
    </button>
  )
}
