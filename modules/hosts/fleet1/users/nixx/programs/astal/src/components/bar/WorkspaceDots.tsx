import { For } from "ags"
import { Gtk } from "ags/gtk4"
import { useWorkspaces, focusWorkspace } from "../../lib/niri"
import { NiriWorkspace } from "../../types/niri"

export default function WorkspaceDots() {
  const workspaces = useWorkspaces()

  return (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      spacing={4}
      class="p-1 bg-slate-900 border border-slate-800 rounded-lg"
    >
      <For each={workspaces((list) => (list ? [...list].sort((a, b) => a.idx - b.idx) : []))}>
        {(ws: NiriWorkspace) => {
          const isActive = ws.is_focused || ws.is_active

          return (
            <button
              class={isActive ? "ws-btn active" : "ws-btn"}
              onClicked={() => focusWorkspace(ws.idx)}
            >
              <label label={String(ws.idx)} />
            </button>
          )
        }}
      </For>
    </box>
  )
}
