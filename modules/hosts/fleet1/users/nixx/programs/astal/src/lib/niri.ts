import { createState } from "ags"
import { subprocess, execAsync } from "ags/process"
import { NiriWorkspace } from "../types/niri"

const [workspaces, setWorkspaces] = createState<NiriWorkspace[]>([])

function sortWorkspaces(list: NiriWorkspace[]): NiriWorkspace[] {
  if (!Array.isArray(list)) return []
  return [...list].sort((a, b) => a.idx - b.idx)
}

async function fetchWorkspaces() {
  try {
    const raw = await execAsync("niri msg -j workspaces")
    const parsed: NiriWorkspace[] = JSON.parse(raw)
    setWorkspaces(sortWorkspaces(parsed))
  } catch (err) {
    console.error("Failed to query initial niri workspaces:", err)
  }
}

// Initial fetch
fetchWorkspaces()

// Listen to niri event-stream
try {
  subprocess("niri msg --json event-stream", (line: string) => {
    try {
      const event = JSON.parse(line)
      if (event.WorkspacesChanged) {
        setWorkspaces(sortWorkspaces(event.WorkspacesChanged.workspaces))
      } else if (
        event.WorkspaceActiveWindowChanged ||
        event.WindowFocusChanged ||
        event.WindowsChanged
      ) {
        fetchWorkspaces()
      }
    } catch {
      // ignore partial / non-json chunks
    }
  })
} catch (err) {
  console.error("Failed to start niri event-stream listener:", err)
}

export function useWorkspaces() {
  return workspaces
}

export function focusWorkspace(idx: number) {
  execAsync(`niri msg action focus-workspace ${idx}`).catch(console.error)
}
