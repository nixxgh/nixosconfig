import app from "ags/gtk4/app"
import { For, createState } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import AstalApps from "gi://AstalApps"
import Graphene from "gi://Graphene"
import AppItem from "../components/launcher/AppItem"
import { shouldShowApp } from "../utils/categories"

const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

export default function LauncherLayout() {
  let contentbox: Gtk.Box
  let searchentry: Gtk.Entry
  let win: Astal.Window

  const apps = new AstalApps.Apps()
  const [list, setList] = createState(new Array<AstalApps.Application>())

  function updateList(text: string) {
    if (text === "") {
      const filtered = apps.list.filter(shouldShowApp).slice(0, 15)
      setList(filtered)
    } else {
      const results = apps.fuzzy_query(text).filter(shouldShowApp).slice(0, 15)
      setList(results)
    }
  }

  function launch(targetApp?: AstalApps.Application) {
    if (targetApp) {
      win.visible = false
      targetApp.launch()
    }
  }

  function onKey(
    _e: Gtk.EventControllerKey,
    keyval: number,
  ) {
    if (keyval === Gdk.KEY_Escape) {
      win.visible = false
      return true
    }
    if (keyval === Gdk.KEY_Return) {
      const currentList = list.get()
      if (currentList.length > 0) {
        launch(currentList[0])
        return true
      }
    }
    return false
  }

  function onClick(_e: Gtk.GestureClick, _: number, x: number, y: number) {
    if (!contentbox) return
    const [, rect] = contentbox.compute_bounds(win)
    const position = new Graphene.Point({ x, y })

    if (!rect.contains_point(position)) {
      win.visible = false
      return true
    }
    return false
  }

  return (
    <window
      $={(ref) => (win = ref)}
      name="launcher"
      class="Launcher"
      application={app}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.EXCLUSIVE}
      visible={false}
      onNotifyVisible={({ visible }) => {
        if (visible) {
          updateList("")
          searchentry?.grab_focus()
        } else {
          searchentry?.set_text("")
        }
      }}
    >
      <Gtk.EventControllerKey onKeyPressed={onKey} />
      <Gtk.GestureClick onPressed={onClick} />

      <box
        $={(ref) => (contentbox = ref)}
        valign={Gtk.Align.CENTER}
        halign={Gtk.Align.CENTER}
        orientation={Gtk.Orientation.VERTICAL}
        widthRequest={480}
        spacing={12}
        class="p-4 bg-slate-950 border border-slate-800 rounded-xl"
      >
        <entry
          $={(ref) => (searchentry = ref)}
          class="p-3 bg-slate-900 border border-slate-800 rounded-lg text-white font-medium"
          placeholderText="Search applications..."
          onNotifyText={({ text }) => updateList(text)}
        />

        <scrolledwindow
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
          vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          minContentHeight={320}
          maxContentHeight={420}
          class="scrolled-app-list"
        >
          <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
            <For each={list}>
              {(item) => (
                <AppItem
                  app={item}
                  onSelect={() => launch(item)}
                />
              )}
            </For>
          </box>
        </scrolledwindow>
      </box>
    </window>
  )
}
