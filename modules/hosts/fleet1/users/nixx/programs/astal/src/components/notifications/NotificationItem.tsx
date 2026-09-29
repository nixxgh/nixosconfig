import { Gtk } from "ags/gtk4"
import AstalNotifd from "gi://AstalNotifd"
import { formatTime } from "../../utils/formatters"
import { NotificationItemProps } from "../../types/types"

export default function NotificationItem({ notification: n }: NotificationItemProps) {
  return (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      spacing={8}
      class="p-3 mb-2 bg-slate-900 border border-slate-800 rounded-lg"
    >
      {/* Header */}
      <centerbox>
        <box $type="start" spacing={8}>
          {n.appIcon && (
            <image
              pixelSize={18}
              iconName={n.appIcon}
            />
          )}
          <label
            class="text-xs font-semibold text-emerald-400"
            label={n.appName || "Notification"}
          />
        </box>
        <box $type="center" />
        <box $type="end" spacing={8}>
          <label
            class="text-xs text-slate-400"
            label={formatTime(n.time)}
          />
          <button
            class="p-1 rounded hover:bg-slate-800 text-slate-400 hover:text-white"
            onClicked={() => n.dismiss()}
          >
            <image iconName="window-close-symbolic" />
          </button>
        </box>
      </centerbox>

      {/* Content */}
      <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
        <label
          xalign={0}
          class="text-sm font-bold text-white"
          label={n.summary}
          wrap
        />
        {n.body && (
          <label
            xalign={0}
            class="text-xs text-slate-200"
            label={n.body}
            wrap
          />
        )}
      </box>

      {/* Action Buttons */}
      {n.actions.length > 0 && (
        <box spacing={8} class="mt-1">
          {n.actions.map(({ label, id }) => (
            <button
              class="px-2.5 py-1 rounded bg-slate-800 hover:bg-emerald-500/20 text-xs font-medium text-slate-200 hover:text-emerald-400"
              onClicked={() => n.invoke(id)}
            >
              <label label={label} />
            </button>
          ))}
        </box>
      )}
    </box>
  )
}
