import app from "ags/gtk4/app"
import { For, createBinding } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import AstalNotifd from "gi://AstalNotifd"
import NotificationItem from "../components/notifications/NotificationItem"

const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor

export default function NotificationLayout() {
  const notifd = AstalNotifd.get_default()
  if (!notifd) return null

  const notifications = createBinding(notifd, "notifications")
  const dontDisturb = createBinding(notifd, "dontDisturb")

  function clearAll() {
    const list = notifd.notifications || []
    for (const n of list) {
      n.dismiss()
    }
  }

  function toggleDND() {
    notifd.set_dont_disturb(!notifd.dontDisturb)
  }

  return (
    <window
      name="notifications"
      class="Notifications"
      application={app}
      anchor={TOP | BOTTOM | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_e, keyval) => {
          if (keyval === Gdk.KEY_Escape) {
            app.toggle_window("notifications")
            return true
          }
          return false
        }}
      />

      <box
        orientation={Gtk.Orientation.VERTICAL}
        widthRequest={380}
        class="p-4 bg-slate-950 border-l border-slate-800"
      >
        {/* Header Controls */}
        <centerbox class="pb-3 border-b border-slate-800">
          <box $type="start">
            <label class="text-base font-bold text-white" label="Notifications" />
          </box>
          <box $type="center" />
          <box $type="end" spacing={8}>
            <button
              class={dontDisturb((dnd) =>
                dnd
                  ? "px-2 py-1 rounded text-xs font-semibold bg-emerald-400 text-slate-950"
                  : "px-2 py-1 rounded text-xs font-medium text-slate-400 hover:text-white"
              )}
              onClicked={toggleDND}
            >
              <label label={dontDisturb((dnd) => (dnd ? "DND ON" : "DND OFF"))} />
            </button>

            <button
              class="px-2 py-1 rounded text-xs font-medium text-slate-400 hover:text-white"
              onClicked={clearAll}
            >
              <label label="Clear All" />
            </button>
          </box>
        </centerbox>

        {/* Notifications History List */}
        <scrolledwindow
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
          vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          vexpand
          class="my-3"
        >
          <box orientation={Gtk.Orientation.VERTICAL}>
            <label
              visible={notifications((ns) => ns.length === 0)}
              class="text-sm text-slate-400 my-8"
              label="No notifications"
            />
            <For each={notifications}>
              {(item) => <NotificationItem notification={item} />}
            </For>
          </box>
        </scrolledwindow>
      </box>
    </window>
  )
}
