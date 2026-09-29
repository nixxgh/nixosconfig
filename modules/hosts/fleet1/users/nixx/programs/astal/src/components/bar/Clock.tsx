import GLib from "gi://GLib"
import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { ClockProps } from "../../types/types"

export default function Clock({ format = "%H:%M" }: ClockProps) {
  const time = createPoll("", 1000, () => {
    return GLib.DateTime.new_now_local().format(format) || ""
  })

  return (
    <menubutton class="status-btn">
      <label label={time} />
      <popover autohide={false} position={Gtk.PositionType.TOP}>
        <box>
          <Gtk.Calendar />
        </box>
      </popover>
    </menubutton>
  )
}
