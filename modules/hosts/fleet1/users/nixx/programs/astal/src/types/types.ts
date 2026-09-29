import AstalApps from "gi://AstalApps"
import AstalNotifd from "gi://AstalNotifd"

export interface AppItemProps {
  app: AstalApps.Application
  onSelect: () => void
}

export interface NotificationItemProps {
  notification: AstalNotifd.Notification
}

export interface ClockProps {
  format?: string
}
