import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import { getAudio, setVolume } from "../../lib/wireplumber"
import { formatPercentage } from "../../utils/formatters"

export default function AudioVolume() {
  const speaker = getAudio()
  if (!speaker) return <box />

  const volume = createBinding(speaker, "volume")
  const icon = createBinding(speaker, "volumeIcon")
  const percent = volume(formatPercentage)

  return (
    <menubutton class="status-btn">
      <box spacing={2}>
        <image iconName={icon} />
        <label label={percent} />
      </box>
      <popover autohide={false} position={Gtk.PositionType.TOP}>
        <box>
          <slider
            widthRequest={180}
            value={volume}
            onChangeValue={({ value }) => setVolume(value)}
          />
        </box>
      </popover>
    </menubutton>
  )
}
