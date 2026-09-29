import { AppItemProps } from "../../types/types"

export default function AppItem({ app, onSelect }: AppItemProps) {
  return (
    <button
      class="p-2.5 rounded-lg hover:bg-slate-900 border border-transparent hover:border-slate-800"
      onClicked={onSelect}
    >
      <box spacing={12}>
        {app.iconName && (
          <image
            pixelSize={32}
            iconName={app.iconName}
          />
        )}
        <box orientation={1}>
          <label
            xalign={0}
            class="text-sm font-semibold text-white"
            label={app.name || app.entry || "App"}
          />
          {app.description && (
            <label
              xalign={0}
              class="text-xs text-slate-200"
              maxWidthChars={50}
              label={app.description}
            />
          )}
        </box>
      </box>
    </button>
  )
}
