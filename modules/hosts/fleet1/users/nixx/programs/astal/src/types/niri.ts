export interface NiriWorkspace {
  id: number
  idx: number
  name: string | null
  output: string
  is_urgent: boolean
  is_active: boolean
  is_focused: boolean
  active_window_id: number | null
}

export interface NiriWindow {
  id: number
  title: string | null
  app_id: string | null
  pid: number | null
  workspace_id: number | null
  is_focused: boolean
  is_floating: boolean
  is_urgent: boolean
}
