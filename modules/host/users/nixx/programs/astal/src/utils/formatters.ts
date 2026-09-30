import GLib from "gi://GLib"

export function formatTime(unixTime?: number, format: string = "%H:%M"): string {
  if (unixTime) {
    return GLib.DateTime.new_from_unix_local(unixTime).format(format) || ""
  }
  return GLib.DateTime.new_now_local().format(format) || ""
}

export function formatPercentage(ratio: number): string {
  return `${Math.round(ratio * 100)}%`
}
