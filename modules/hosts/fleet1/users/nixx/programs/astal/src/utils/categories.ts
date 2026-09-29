import AstalApps from "gi://AstalApps"

const BLACKLISTED_CATEGORIES = new Set([
  "Settings",
  "HardwareSettings",
  "System",
  "Documentation",
])

const BLACKLISTED_ENTRIES = new Set([
  "xterm",
  "nixos-manual",
  "blueman-adapters",
  "blueman-manager",
])

export function shouldShowApp(app: AstalApps.Application): boolean {
  const entry = (app.entry || "").toLowerCase()
  for (const blacklisted of BLACKLISTED_ENTRIES) {
    if (entry.includes(blacklisted)) return false
  }

  // Categories can be an array of strings or null
  const categories = app.categories
  if (Array.isArray(categories)) {
    // If every category of the app is in the blacklist, filter it out
    const allBlacklisted = categories.length > 0 && categories.every((cat) => BLACKLISTED_CATEGORIES.has(cat))
    if (allBlacklisted) return false
  }

  return true
}
