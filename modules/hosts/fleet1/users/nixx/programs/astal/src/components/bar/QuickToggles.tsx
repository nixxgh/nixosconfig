import { execAsync } from "ags/process"
import { createPoll } from "ags/time"

export default function QuickToggles() {
  const caffeineActive = createPoll(false, 3000, async () => {
    try {
      await execAsync("systemctl --user is-active --quiet hypridle")
      return false // hypridle running means caffeine is inactive
    } catch {
      return true // hypridle stopped means caffeine is active
    }
  })

  const nightlightActive = createPoll(false, 3000, async () => {
    try {
      await execAsync("systemctl --user is-active --quiet wlsunset || systemctl --user is-active --quiet wlsunset-forced")
      return true
    } catch {
      return false
    }
  })

  async function toggleCaffeine() {
    try {
      const active = caffeineActive.get()
      if (active) {
        await execAsync("systemctl --user start hypridle")
      } else {
        await execAsync("systemctl --user stop hypridle")
      }
    } catch (err) {
      console.error("Failed to toggle caffeine:", err)
    }
  }

  async function toggleNightlight() {
    try {
      const active = nightlightActive.get()
      if (active) {
        await execAsync("systemctl --user stop wlsunset-forced wlsunset")
      } else {
        await execAsync("systemctl --user start wlsunset")
      }
    } catch (err) {
      console.error("Failed to toggle nightlight:", err)
    }
  }

  return (
    <box spacing={4}>
      <button
        class={caffeineActive((active) => (active ? "toggle-btn active" : "toggle-btn"))}
        onClicked={toggleCaffeine}
      >
        <label label="CAF" />
      </button>

      <button
        class={nightlightActive((active) => (active ? "toggle-btn active" : "toggle-btn"))}
        onClicked={toggleNightlight}
      >
        <label label="NIT" />
      </button>
    </box>
  )
}
