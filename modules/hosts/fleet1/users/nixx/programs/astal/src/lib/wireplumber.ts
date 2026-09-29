import AstalWp from "gi://AstalWp"

export function getAudio() {
  const wp = AstalWp.get_default()
  return wp?.defaultSpeaker || null
}

export function setVolume(val: number) {
  const speaker = getAudio()
  if (speaker) {
    speaker.set_volume(Math.max(0, Math.min(1, val)))
  }
}

export function stepVolume(delta: number) {
  const speaker = getAudio()
  if (speaker) {
    speaker.set_volume(Math.max(0, Math.min(1, speaker.volume + delta)))
  }
}

export function toggleMute() {
  const speaker = getAudio()
  if (speaker) {
    speaker.set_mute(!speaker.mute)
  }
}
