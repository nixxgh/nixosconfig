import app from "ags/gtk4/app"
import style from "./src/style.css"
import BarLayout from "./src/layouts/BarLayout"
import LauncherLayout from "./src/layouts/LauncherLayout"
import NotificationLayout from "./src/layouts/NotificationLayout"
import DeckLayout from "./src/layouts/DeckLayout"

app.start({
  css: style,
  main() {
    app.get_monitors().map(BarLayout)
    LauncherLayout()
    NotificationLayout()
    DeckLayout()
  },
})
