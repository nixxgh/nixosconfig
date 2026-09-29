import { createPoll } from "ags/time"
import { execAsync } from "ags/process"

export default function BatteryMeter() {
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

  const icon = batteryData(({ cap, charging }) => {
    const suffix = charging ? "-charging" : ""
    if (cap >= 80) return `battery-full${suffix}-symbolic`
    if (cap >= 30) return `battery-good${suffix}-symbolic`
    return `battery-empty${suffix}-symbolic`
  })

  const label = batteryData(({ cap }) => `${cap}%`)

  return (
    <menubutton class="status-btn">
      <box spacing={2}>
        <image iconName={icon} />
        <label label={label} />
      </box>
    </menubutton>
  )
}
