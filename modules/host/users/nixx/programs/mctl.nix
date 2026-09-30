{ self, inputs, ... }: {
  flake.homeModules.mctl =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      mctlPkg = pkgs.writeScriptBin "mctl" ''
        #!${pkgs.python3}/bin/python3
        import curses
        from importlib.machinery import SourceFileLoader
        import os
        import subprocess
        import sys
        import tempfile
        import threading
        import time

        def run_cmd(cmd):
            try:
                res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, check=False)
                return res.stdout.strip()
            except Exception:
                return ""

        def fire_cmd(cmd):
            try:
                subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass

        def get_media():
            fmt = "{{playerName}}||{{status}}||{{artist}}||{{title}}||{{position}}||{{mpris:length}}"
            out = run_cmd(["${pkgs.playerctl}/bin/playerctl", "metadata", "--format", fmt])
            if not out:
                return None
            parts = out.split("||")
            if len(parts) < 4:
                return None
            player = parts[0]
            status = parts[1]
            artist = parts[2]
            title = parts[3]
            pos = 0
            length = 0
            if len(parts) >= 5:
                try:
                    val = float(parts[4])
                    pos = int(val // 1000000) if val > 100000 else int(val)
                except ValueError:
                    pass
            if len(parts) >= 6:
                try:
                    val = float(parts[5])
                    length = int(val // 1000000) if val > 100000 else int(val)
                except ValueError:
                    pass
            return {
                "player": player,
                "status": status,
                "artist": artist,
                "title": title,
                "pos": pos,
                "length": length
            }

        def fmt_time(sec):
            sec = max(0, int(sec))
            m = sec // 60
            s = sec % 60
            if m >= 60:
                h = m // 60
                m = m % 60
                return f"{h:02d}:{m:02d}:{s:02d}"
            return f"{m:02d}:{s:02d}"

        def draw_bar(val, max_val, width=20):
            if max_val <= 0 or width <= 0:
                return "░" * max(1, width)
            fill = int(min(max(val / max_val, 0), 1) * width)
            return "█" * fill + "░" * (width - fill)

        def safe_addstr(stdscr, y, x, s, attr=0):
            h, w = stdscr.getmaxyx()
            if 0 <= y < h and 0 <= x < w:
                try:
                    stdscr.addstr(y, x, s[:w - x - 1], attr)
                except curses.error:
                    pass

        def x_to_ratio(mx, b_width):
            if mx <= 13:
                return 0.0
            elif mx >= 12 + b_width:
                return 1.0
            else:
                return (mx - 13) / max(1, b_width - 1)

        def prompt_seek(stdscr, h, w, media):
            prompt = "Seek to (e.g. 1:30, 45, +15s, 50%): "
            py = min(h - 1, 12)
            safe_addstr(stdscr, py, 2, " " * (w - 4))
            safe_addstr(stdscr, py, 2, prompt, curses.color_pair(5) | curses.A_BOLD)
            stdscr.refresh()
            curses.echo()
            curses.curs_set(1)
            stdscr.timeout(-1)
            try:
                inp = stdscr.getstr(py, 2 + len(prompt), 20).decode('utf-8', errors='ignore').strip()
            except Exception:
                inp = ""
            curses.noecho()
            curses.curs_set(0)
            stdscr.timeout(35)
            if not inp:
                return None

            if inp.endswith('%') and media and media["length"] > 0:
                try:
                    pct = float(inp[:-1]) / 100.0
                    target = int(media["length"] * max(0.0, min(1.0, pct)))
                    fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", str(target)])
                    return target
                except ValueError:
                    pass
            elif inp.startswith('+') or inp.startswith('-'):
                clean = inp.rstrip('sS')
                try:
                    offset = abs(int(clean))
                    sign = "+" if inp.startswith('+') else "-"
                    fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", f"{offset}{sign}"])
                except ValueError:
                    pass
            elif ":" in inp:
                parts = inp.split(":")
                try:
                    if len(parts) == 2:
                        target = int(parts[0]) * 60 + int(parts[1])
                    elif len(parts) == 3:
                        target = int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
                    else:
                        target = -1
                    if target >= 0:
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", str(target)])
                        return target
                except ValueError:
                    pass
            else:
                clean = inp.rstrip('sS')
                try:
                    target = int(clean)
                    fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", str(target)])
                    return target
                except ValueError:
                    pass
            return None

        # Load pulsemixer core engine
        pm = None
        try:
            loader = SourceFileLoader('pulsemixer', '${pkgs.pulsemixer}/bin/pulsemixer')
            pm = loader.load_module()
            pm.CFG = pm.Config().load()
            pm.PULSE = pm.Pulse('mctl', reconnect=True)
        except Exception:
            pm = None

        class EmbeddedPulseScreen(pm.Screen if pm else object):
            def __init__(self, win, h, w):
                self.screen = win
                self.update_dimensions(win, h, w)
                self.index = 0
                self.top_line_num = 0
                self.focus_line_num = 0
                self.info, self.menu = str, str
                self.mode_keys = ['F1', 'F2', 'F3']
                self.menu_titles = ['F1 Output', 'F2 Input', 'F3 Cards']
                self.data = []
                self.mode = {0: 1, 1: 0, 2: 0}
                self.modes_data = [[[], 0, 0] for _ in range(6)]
                self.active_mode = 0
                self.old_mode = 0
                self.change_mode_allowed = True
                self.n_lines = 0
                self.color_mode = 2
                self.green = curses.color_pair(2)
                self.yellow = curses.color_pair(5)
                self.red = curses.color_pair(4)
                self.muted_color = curses.color_pair(4)
                try:
                    curses.init_pair(240, 240, -1)
                    curses.init_pair(243, 243, -1)
                    curses.init_pair(246, 246, -1)
                    self.gray_gradient = [curses.color_pair(240), curses.color_pair(243), curses.color_pair(246)]
                except Exception:
                    self.gray_gradient = [curses.A_NORMAL] * 3
                self.gradient = [self.green, self.yellow, self.red]
                self.submenu_show = False
                self.helpwin_show = False
                self.selected = None
                self.action = None
                self.server_info = pm.PULSE.get_server_info() if pm and pm.PULSE else None

            def update_dimensions(self, win, h, w):
                self.screen = win
                self.h = h
                self.w = w
                self.lines = max(1, h - 2)
                self.cols = max(10, w - 1)

            def display_line(self, index, line, mod=curses.A_NORMAL, win=None):
                target_win = win or self.screen
                if not (0 <= index < self.h):
                    return
                shift = 0
                for i in line.split('\n'):
                    parts = i.rsplit('|')
                    head = "".join(parts[:-1])
                    tail = int(parts[-1] or 0)
                    if 0 <= shift < self.w:
                        text = head[:self.w - shift - 1]
                        if text:
                            try:
                                target_win.addstr(index, shift, text, tail | mod)
                            except curses.error:
                                pass
                    shift += len(head)

        def main(stdscr):
            curses.curs_set(0)
            try:
                curses.mousemask(curses.ALL_MOUSE_EVENTS | curses.REPORT_MOUSE_POSITION)
            except Exception:
                pass
            sys.stdout.write("\033[?1002h")
            sys.stdout.flush()

            stdscr.timeout(35)
            curses.start_color()
            try:
                curses.use_default_colors()
            except Exception:
                pass

            curses.init_pair(1, curses.COLOR_CYAN, -1)
            curses.init_pair(2, curses.COLOR_GREEN, -1)
            curses.init_pair(3, curses.COLOR_MAGENTA, -1)
            curses.init_pair(4, curses.COLOR_RED, -1)
            curses.init_pair(5, curses.COLOR_YELLOW, -1)

            # Spawn embedded CAVA visualizer with 64 frequency bars
            cava_cfg = (
                "[general]\n"
                "bars = 64\n"
                "framerate = 30\n"
                "[input]\n"
                "method = pipewire\n"
                "[output]\n"
                "method = raw\n"
                "raw_target = /dev/stdout\n"
                "data_format = ascii\n"
                "ascii_max_range = 100\n"
                "bar_delimiter = 59\n"
                "frame_delimiter = 10\n"
                "[smoothing]\n"
                "noise_reduction = 77\n"
            )
            cava_tmp = tempfile.NamedTemporaryFile("w", delete=False)
            cava_tmp.write(cava_cfg)
            cava_tmp.flush()
            cava_cfg_path = cava_tmp.name
            cava_tmp.close()

            cava_data = [[]]
            try:
                cava_proc = subprocess.Popen(
                    ["${pkgs.cava}/bin/cava", "-p", cava_cfg_path],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                    text=True,
                    bufsize=1
                )
            except Exception:
                cava_proc = None

            def cava_worker():
                if not cava_proc or not cava_proc.stdout:
                    return
                while True:
                    line = cava_proc.stdout.readline()
                    if not line:
                        break
                    try:
                        vals = [int(x) for x in line.strip().split(';') if x.isdigit()]
                        if vals:
                            cava_data[0] = vals
                    except Exception:
                        pass

            if cava_proc:
                t = threading.Thread(target=cava_worker, daemon=True)
                t.start()

            seek_target = None
            seek_time = 0.0
            cached_media = None
            last_poll_time = 0.0
            last_pm_poll = 0.0

            drag_mode = None  # None or 'progress'
            drag_val = 0
            last_drag_time = 0.0
            btn_regions = []

            blocks = [" ", " ", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
            all_row_colors = [
                curses.color_pair(4) | curses.A_BOLD,  # Red (top peak)
                curses.color_pair(3) | curses.A_BOLD,  # Magenta
                curses.color_pair(5) | curses.A_BOLD,  # Yellow
                curses.color_pair(2) | curses.A_BOLD,  # Green
                curses.color_pair(1) | curses.A_BOLD,  # Cyan (base)
            ]

            # Initialize Embedded Pulsemixer Subwindow
            pm_win = None
            eps = None
            old_h, old_w = 0, 0

            try:
                while True:
                    now = time.time()
                    h, w = stdscr.getmaxyx()
                    b_width = max(10, min(28, w - 32))

                    # Adaptive CAVA height
                    if h >= 26:
                        cava_lines = 4
                    elif h >= 22:
                        cava_lines = 3
                    elif h >= 18:
                        cava_lines = 2
                    else:
                        cava_lines = 1

                    info_start_y = 1 + cava_lines + 1
                    time_row = info_start_y + 3
                    btn_row = info_start_y + 4
                    pm_start_y = btn_row + 2
                    ctrl_y1 = max(pm_start_y + 4, h - 3)
                    ctrl_y2 = ctrl_y1 + 1
                    pm_h = max(3, ctrl_y1 - 1 - pm_start_y)
                    pm_w = max(10, w - 2)

                    # Manage pulsemixer subwindow resize / instantiation
                    if (h, w) != (old_h, old_w) or pm_win is None:
                        old_h, old_w = h, w
                        try:
                            pm_win = curses.newwin(pm_h, pm_w, pm_start_y, 1)
                        except Exception:
                            pm_win = None
                        if pm and pm.PULSE and pm.PULSE.connected:
                            if eps is None and pm_win:
                                eps = EmbeddedPulseScreen(pm_win, pm_h, pm_w)
                            elif eps and pm_win:
                                eps.update_dimensions(pm_win, pm_h, pm_w)

                    # Auto-commit drag if no events arrived for 0.4s
                    if drag_mode is not None and now - last_drag_time > 0.4:
                        if drag_mode == 'progress' and cached_media:
                            fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", str(drag_val)])
                            seek_target = drag_val
                            seek_time = now
                        drag_mode = None
                        stdscr.timeout(35)

                    # Poll MPRIS
                    if drag_mode is None:
                        if now - last_poll_time >= 0.35:
                            cached_media = get_media()
                            last_poll_time = now
                    media = cached_media

                    # Poll pulsemixer streams
                    if eps and (now - last_pm_poll >= 0.25):
                        try:
                            eps.get_data()
                        except Exception:
                            pass
                        last_pm_poll = now

                    # Calculate display position
                    if drag_mode == 'progress':
                        display_pos = drag_val
                    elif seek_target is not None:
                        if now - seek_time < 1.0:
                            if abs((media["pos"] if media else 0) - seek_target) > 3:
                                display_pos = seek_target
                            else:
                                seek_target = None
                                display_pos = media["pos"] if media else 0
                        else:
                            seek_target = None
                            display_pos = media["pos"] if media else 0
                    else:
                        display_pos = media["pos"] if media else 0

                    stdscr.erase()

                    # Render Enhanced CAVA Audio Visualizer
                    raw_bars = cava_data[0] if cava_data[0] else [0] * 64
                    vis_width = min(len(raw_bars), max(16, min(64, w - 6)))
                    bars_to_show = raw_bars[:vis_width]

                    max_level = cava_lines * 8
                    scaled_bars = [int(v * max_level / 100.0) for v in bars_to_show]
                    active_colors = all_row_colors[-cava_lines:]

                    for r in range(cava_lines):
                        level = cava_lines - 1 - r
                        row_chars = []
                        for s in scaled_bars:
                            rem = s - level * 8
                            if rem <= 0:
                                row_chars.append(" ")
                            elif rem >= 8:
                                row_chars.append("█")
                            else:
                                row_chars.append(blocks[rem])
                        row_str = "".join(row_chars)
                        cx = max(2, (w - len(row_str)) // 2)
                        safe_addstr(stdscr, 1 + r, cx, row_str, active_colors[r])

                    safe_addstr(stdscr, 1 + cava_lines, 2, "─" * max(0, w - 4), curses.color_pair(1))

                    # Media Info
                    if media:
                        stat_icon = "▶" if media["status"] == "Playing" else ("⏸" if media["status"] == "Paused" else "⏹")
                        stat_color = curses.color_pair(2) if media["status"] == "Playing" else curses.color_pair(5)

                        safe_addstr(stdscr, info_start_y, 3, "Player : ", curses.A_BOLD)
                        safe_addstr(stdscr, info_start_y, 12, f"{media['player'].capitalize()} [{stat_icon} {media['status']}]", stat_color | curses.A_BOLD)

                        safe_addstr(stdscr, info_start_y + 1, 3, "Track  : ", curses.A_BOLD)
                        safe_addstr(stdscr, info_start_y + 1, 12, media['title'] or 'Unknown Title', curses.A_BOLD)

                        safe_addstr(stdscr, info_start_y + 2, 3, "Artist : ", curses.A_BOLD)
                        safe_addstr(stdscr, info_start_y + 2, 12, media['artist'] or 'Unknown Artist', curses.color_pair(1))

                        # Progress Bar Slider (time_row)
                        safe_addstr(stdscr, time_row, 3, "Time   : ", curses.A_BOLD)
                        if media["length"] > 0:
                            prog_bar = f"[{draw_bar(display_pos, media['length'], b_width)}]"
                            drag_tag = " (scrubbing)" if drag_mode == 'progress' else ""
                            time_str = f" {fmt_time(display_pos)} / {fmt_time(media['length'])}{drag_tag}"
                            safe_addstr(stdscr, time_row, 12, prog_bar)
                            safe_addstr(stdscr, time_row, 12 + len(prog_bar), time_str, curses.color_pair(2) if drag_mode != 'progress' else curses.color_pair(5))
                        else:
                            safe_addstr(stdscr, time_row, 12, f"{fmt_time(display_pos)} (Live stream / unknown length)", curses.A_DIM)

                        # 5 Interactive Control Buttons under Progress Bar (btn_row)
                        safe_addstr(stdscr, btn_row, 3, "Control: ", curses.A_BOLD)
                        is_playing = media["status"] == "Playing"
                        if w >= 58:
                            b1 = "[⏮ Prev]"
                            b2 = "[-10s]"
                            b3 = "[⏸ Pause]" if is_playing else "[▶ Play]"
                            b4 = "[+10s]"
                            b5 = "[Next ⏭]"
                        else:
                            b1 = "[⏮]"
                            b2 = "[-10]"
                            b3 = "[⏸]" if is_playing else "[▶]"
                            b4 = "[+10]"
                            b5 = "[⏭]"

                        btns_data = [
                            ("prev", b1, curses.color_pair(1) | curses.A_BOLD),
                            ("b10", b2, curses.color_pair(1) | curses.A_BOLD),
                            ("toggle", b3, (curses.color_pair(2) if is_playing else curses.color_pair(5)) | curses.A_BOLD),
                            ("f10", b4, curses.color_pair(1) | curses.A_BOLD),
                            ("next", b5, curses.color_pair(1) | curses.A_BOLD),
                        ]

                        btn_regions = []
                        bx = 12
                        spacing = 2 if w >= 58 else 1
                        for action, text, color in btns_data:
                            safe_addstr(stdscr, btn_row, bx, text, color)
                            btn_regions.append((action, bx, bx + len(text)))
                            bx += len(text) + spacing
                    else:
                        safe_addstr(stdscr, info_start_y, 3, "Player : ", curses.A_BOLD)
                        safe_addstr(stdscr, info_start_y, 12, "Idle", curses.A_DIM)
                        safe_addstr(stdscr, info_start_y + 1, 3, "Track  : ", curses.A_BOLD)
                        safe_addstr(stdscr, info_start_y + 1, 12, "No active MPRIS player detected", curses.color_pair(5))
                        safe_addstr(stdscr, info_start_y + 2, 3, "Artist : ", curses.A_BOLD)
                        safe_addstr(stdscr, info_start_y + 2, 12, "(Start Spotify, Zen Browser, or MPV)", curses.A_DIM)
                        safe_addstr(stdscr, time_row, 3, "Time   : ", curses.A_BOLD)
                        safe_addstr(stdscr, time_row, 12, "--:-- / --:--", curses.A_DIM)
                        safe_addstr(stdscr, btn_row, 3, "Control: ", curses.A_BOLD)
                        safe_addstr(stdscr, btn_row, 12, "[⏮ Prev]  [-10s]  [▶ Play]  [+10s]  [Next ⏭]", curses.A_DIM)
                        btn_regions = []

                    # Separator above Pulsemixer section
                    safe_addstr(stdscr, btn_row + 1, 2, "─" * max(0, w - 4), curses.color_pair(1))

                    # Render Pulsemixer UI in subwindow
                    if eps and pm_win:
                        try:
                            pm_win.erase()
                            eps.update_menu()
                            eps.update_info()
                            eps.display()
                            pm_win.noutrefresh()
                        except Exception:
                            pass

                    # Controls Footer
                    safe_addstr(stdscr, ctrl_y1 - 1, 2, "─" * max(0, w - 4), curses.color_pair(1))
                    ctrls1 = "[Space] Play/Pause   [u/i] Prev/Next Track   [H/L] Seek ±10s   [Mouse] Controls & Scrub"
                    ctrls2 = "[j/k / ↑↓] Select Stream   [h/l / ←→] Vol ±2%   [m] Mute   [Tab] Mode   [q] Quit"
                    safe_addstr(stdscr, ctrl_y1, max(0, (w - len(ctrls1)) // 2), ctrls1, curses.A_DIM)
                    safe_addstr(stdscr, ctrl_y2, max(0, (w - len(ctrls2)) // 2), ctrls2, curses.A_DIM)

                    stdscr.refresh()

                    try:
                        key = stdscr.getch()
                    except KeyboardInterrupt:
                        break

                    if key in (ord('q'), ord('Q'), 27):
                        break
                    elif key == ord(' '):
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "play-pause"])
                    elif key in (ord('i'), ord('I'), ord('n'), ord('N')):
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "next"])
                    elif key in (ord('u'), ord('U'), ord('p'), ord('P')):
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "previous"])
                    elif key in (ord('L'), ord('>'), ord(']')):
                        # Seek forward 10s
                        if media and media["length"] > 0:
                            seek_target = min(media["length"], display_pos + 10)
                            seek_time = time.time()
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", "10+"])
                    elif key in (ord('H'), ord('<'), ord('[')):
                        # Seek backward 10s
                        if media and media["length"] > 0:
                            seek_target = max(0, display_pos - 10)
                            seek_time = time.time()
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", "10-"])
                    elif key in (ord('s'), ord('S'), ord(':'), ord('/')):
                        tgt = prompt_seek(stdscr, h, w, media)
                        if tgt is not None:
                            seek_target = tgt
                            seek_time = time.time()
                    elif key == ord('\t'):
                        if eps:
                            eps.cycle_mode()
                            last_pm_poll = 0
                    elif key == curses.KEY_F1 and eps:
                        eps.change_mode(0)
                        last_pm_poll = 0
                    elif key == curses.KEY_F2 and eps:
                        eps.change_mode(1)
                        last_pm_poll = 0
                    elif key == curses.KEY_F3 and eps:
                        eps.change_mode(2)
                        last_pm_poll = 0
                    elif key in (ord('k'), curses.KEY_UP) and eps and eps.data:
                        focus = eps.top_line_num + eps.focus_line_num
                        bar = eps.data[focus][0] if focus < len(eps.data) else None
                        if bar and bar.locked:
                            n = 1 if eps.data[focus][1] == 0 else eps.data[focus][1] + 1
                            for _ in range(n): eps.scroll(eps.UP)
                        else:
                            eps.scroll(eps.UP)
                        if not eps.data[eps.top_line_num + eps.focus_line_num][0]:
                            eps.scroll(eps.UP)
                    elif key in (ord('j'), curses.KEY_DOWN) and eps and eps.data:
                        focus = eps.top_line_num + eps.focus_line_num
                        bar = eps.data[focus][0] if focus < len(eps.data) else None
                        if bar and bar.locked:
                            n = 1 if eps.data[focus][1] == eps.data[focus][3] - 1 else ((eps.data[focus][3] - 1) - eps.data[focus][1]) + 1
                            for _ in range(n): eps.scroll(eps.DOWN)
                        else:
                            eps.scroll(eps.DOWN)
                        if not eps.data[eps.top_line_num + eps.focus_line_num][0]:
                            eps.scroll(eps.DOWN)
                    elif key in (ord('h'), curses.KEY_LEFT, ord('-')) and eps and eps.data:
                        focus = eps.top_line_num + eps.focus_line_num
                        if focus < len(eps.data):
                            bar, side = eps.data[focus][0], eps.data[focus][1]
                            if bar:
                                bar.move(-2, side)
                                last_pm_poll = 0
                    elif key in (ord('l'), curses.KEY_RIGHT, ord('+'), ord('=')) and eps and eps.data:
                        focus = eps.top_line_num + eps.focus_line_num
                        if focus < len(eps.data):
                            bar, side = eps.data[focus][0], eps.data[focus][1]
                            if bar:
                                bar.move(2, side)
                                last_pm_poll = 0
                    elif key in (ord('m'), ord('M')) and eps and eps.data:
                        focus = eps.top_line_num + eps.focus_line_num
                        if focus < len(eps.data):
                            bar = eps.data[focus][0]
                            if bar:
                                bar.mute_toggle()
                                last_pm_poll = 0
                    elif ord('0') <= key <= ord('9') and eps and eps.data:
                        focus = eps.top_line_num + eps.focus_line_num
                        if focus < len(eps.data):
                            bar, side = eps.data[focus][0], eps.data[focus][1]
                            if bar:
                                pct = 100 if key == ord('0') else (key - ord('0')) * 10
                                bar.set(pct, side)
                                last_pm_poll = 0
                    elif key == curses.KEY_MOUSE:
                        try:
                            _, mx, my, _, bstate = curses.getmouse()
                            now_m = time.time()

                            is_press = bool(bstate & (curses.BUTTON1_PRESSED | curses.BUTTON1_CLICKED))
                            is_release = bool(bstate & (curses.BUTTON1_RELEASED | curses.BUTTON1_CLICKED))
                            is_motion = bool(bstate & curses.REPORT_MOUSE_POSITION) or (drag_mode is not None and not is_release)

                            # Handle button click on btn_row (5 buttons under progress bar)
                            if my == btn_row and is_press and drag_mode is None:
                                for action, x1, x2 in btn_regions:
                                    if x1 <= mx <= x2:
                                        if action == "prev":
                                            fire_cmd(["${pkgs.playerctl}/bin/playerctl", "previous"])
                                        elif action == "b10":
                                            if media and media["length"] > 0:
                                                seek_target = max(0, display_pos - 10)
                                                seek_time = now_m
                                            fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", "10-"])
                                        elif action == "toggle":
                                            fire_cmd(["${pkgs.playerctl}/bin/playerctl", "play-pause"])
                                        elif action == "f10":
                                            if media and media["length"] > 0:
                                                seek_target = min(media["length"], display_pos + 10)
                                                seek_time = now_m
                                            fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", "10+"])
                                        elif action == "next":
                                            fire_cmd(["${pkgs.playerctl}/bin/playerctl", "next"])
                                        curses.flushinp()
                                        break

                            # Handle initial press on track progress bar
                            if is_press and drag_mode is None:
                                if my == time_row and media and media["length"] > 0 and (12 <= mx <= 13 + b_width):
                                    drag_mode = 'progress'
                                    drag_val = int(media["length"] * x_to_ratio(mx, b_width))
                                    last_drag_time = now_m
                                    stdscr.timeout(20)

                            # Handle active track scrubbing drag
                            if drag_mode == 'progress' and (is_motion or is_press):
                                last_drag_time = now_m
                                if media and media["length"] > 0:
                                    drag_val = int(media["length"] * x_to_ratio(mx, b_width))

                            # Handle track scrub release commit
                            if is_release and drag_mode == 'progress':
                                last_drag_time = now_m
                                if media and media["length"] > 0:
                                    drag_val = int(media["length"] * x_to_ratio(mx, b_width))
                                    seek_target = drag_val
                                    seek_time = now_m
                                    fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", str(drag_val)])
                                drag_mode = None
                                stdscr.timeout(35)
                                curses.flushinp()

                            # Handle Pulsemixer Mouse Interaction (Tabs, Stream Select, Wheel, Volume Drag)
                            if eps and pm_start_y <= my < pm_start_y + pm_h and drag_mode is None:
                                ry = my - pm_start_y
                                rx = max(0, mx - 1)
                                if ry == 0 and is_press:
                                    f1 = len(eps.menu_titles[0]) + 1
                                    f2 = f1 + len(eps.menu_titles[1]) + 2
                                    f3 = f2 + len(eps.menu_titles[2]) + 3
                                    if rx in range(0, f1):
                                        eps.change_mode(0)
                                    elif rx in range(f1, f2):
                                        eps.change_mode(1)
                                    elif rx in range(f2, f3):
                                        eps.change_mode(2)
                                    last_pm_poll = 0
                                elif ry > 0:
                                    top = eps.top_line_num
                                    visible_data = eps.data[top:top + eps.lines]
                                    line_idx = ry - 1
                                    if 0 <= line_idx < len(visible_data):
                                        data_entry = visible_data[line_idx]
                                        bar_item, side_item = data_entry[0], data_entry[1]
                                        if is_press or (is_motion and (bstate & curses.BUTTON1_PRESSED)):
                                            eps.focus_line_num = line_idx
                                            # If click/drag is within volume bar region
                                            off = 6 * (eps.cols // (43 if eps.cols <= 60 else 25))
                                            bar_start_x = 22 + off + 6
                                            bar_len = max(5, eps.cols - 31 - off)
                                            if rx >= bar_start_x and bar_item:
                                                pct = int(min(1.0, max(0.0, (rx - bar_start_x) / bar_len)) * 100)
                                                bar_item.set(pct, side_item)
                                                last_pm_poll = 0
                                        # Mouse wheel volume adjustments
                                        if hasattr(curses, 'BUTTON4_PRESSED') and (bstate & curses.BUTTON4_PRESSED):
                                            if bar_item:
                                                bar_item.move(3, side_item)
                                                last_pm_poll = 0
                                        elif hasattr(curses, 'BUTTON5_PRESSED') and (bstate & curses.BUTTON5_PRESSED):
                                            if bar_item:
                                                bar_item.move(-3, side_item)
                                                last_pm_poll = 0
                        except Exception:
                            pass
            finally:
                sys.stdout.write("\033[?1002l")
                sys.stdout.flush()
                if cava_proc:
                    try:
                        cava_proc.terminate()
                        cava_proc.wait(timeout=0.3)
                    except Exception:
                        pass
                try:
                    if os.path.exists(cava_cfg_path):
                        os.remove(cava_cfg_path)
                except Exception:
                    pass

        if __name__ == "__main__":
            try:
                curses.wrapper(main)
            except KeyboardInterrupt:
                pass
      '';
    in
    {
      home.packages = [ mctlPkg ];
    };
}
