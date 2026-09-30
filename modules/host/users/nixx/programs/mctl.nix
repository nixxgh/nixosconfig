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

        def get_volume():
            out = run_cmd(["${pkgs.wireplumber}/bin/wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
            vol = 0
            muted = False
            if "MUTED" in out:
                muted = True
            parts = out.split()
            if len(parts) >= 2:
                try:
                    vol = int(float(parts[1]) * 100)
                except ValueError:
                    pass
            return vol, muted

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

        def bar(val, max_val, width=20):
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
            curses.use_default_colors()

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
            vol_lock = None
            last_vol_cmd = 0.0
            cached_media = None
            cached_vol = (0, False)
            last_poll_time = 0.0

            drag_mode = None  # None, 'progress', or 'volume'
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

            try:
                while True:
                    now = time.time()
                    h, w = stdscr.getmaxyx()
                    b_width = max(10, min(28, w - 32))

                    # Adaptive CAVA height: bigger on larger windows, compact on small
                    if h >= 22:
                        cava_lines = 5
                    elif h >= 18:
                        cava_lines = 4
                    elif h >= 15:
                        cava_lines = 3
                    elif h >= 13:
                        cava_lines = 2
                    else:
                        cava_lines = 1

                    info_start_y = 1 + cava_lines + 1
                    time_row = info_start_y + 3
                    btn_row = info_start_y + 4
                    vol_row = info_start_y + 5

                    # Auto-commit drag if no events arrived for 0.4s
                    if drag_mode is not None and now - last_drag_time > 0.4:
                        if drag_mode == 'progress' and cached_media:
                            fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", str(drag_val)])
                            seek_target = drag_val
                            seek_time = now
                        elif drag_mode == 'volume':
                            fire_cmd(["${pkgs.wireplumber}/bin/wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", f"{drag_val}%"])
                            vol_lock = (drag_val, now)
                        drag_mode = None
                        stdscr.timeout(35)

                    # Poll external MPRIS and WirePlumber commands decoupled from 30fps visualizer
                    if drag_mode is None:
                        if now - last_poll_time >= 0.35:
                            cached_media = get_media()
                            cached_vol = get_volume()
                            last_poll_time = now
                    media = cached_media
                    vol, muted = cached_vol

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

                    # Calculate display volume
                    if drag_mode == 'volume':
                        display_vol = drag_val
                    elif vol_lock is not None:
                        if now - vol_lock[1] < 0.8:
                            display_vol = vol_lock[0]
                        else:
                            vol_lock = None
                            display_vol = vol
                    else:
                        display_vol = vol

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
                            prog_bar = f"[{bar(display_pos, media['length'], b_width)}]"
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

                    # Volume Info (vol_row)
                    vol_icon = "🔇 MUTED" if muted else f"🔊 {display_vol}%"
                    vol_color = curses.color_pair(4) if muted else curses.color_pair(2)
                    safe_addstr(stdscr, vol_row, 3, "Volume : ", curses.A_BOLD)
                    vol_bar = f"[{bar(display_vol, 100, b_width)}]"
                    safe_addstr(stdscr, vol_row, 12, vol_bar)
                    safe_addstr(stdscr, vol_row, 12 + len(vol_bar), f" {vol_icon}", vol_color | curses.A_BOLD)

                    # Controls Footer
                    ctrl_y1 = max(vol_row + 2, h - 3)
                    ctrl_y2 = ctrl_y1 + 1
                    safe_addstr(stdscr, ctrl_y1 - 1, 2, "─" * max(0, w - 4), curses.color_pair(1))
                    ctrls1 = "[Space] Play/Pause   [u/i] Prev/Next Track   [h/l] Seek ±10s   [0-9] %"
                    ctrls2 = "[j/k] Vol ±5%        [Mouse] Click Buttons & Drag Sliders      [q] Quit"
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
                    elif key in (ord('l'), curses.KEY_RIGHT, ord('.')):
                        # Seek forward 10s
                        if media and media["length"] > 0:
                            seek_target = min(media["length"], display_pos + 10)
                            seek_time = time.time()
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", "10+"])
                    elif key in (ord('L'), ord('>'), ord(']')):
                        # Seek forward 30s
                        if media and media["length"] > 0:
                            seek_target = min(media["length"], display_pos + 30)
                            seek_time = time.time()
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", "30+"])
                    elif key in (ord('h'), curses.KEY_LEFT, ord(',')):
                        # Seek backward 10s
                        if media and media["length"] > 0:
                            seek_target = max(0, display_pos - 10)
                            seek_time = time.time()
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", "10-"])
                    elif key in (ord('H'), ord('<'), ord('[')):
                        # Seek backward 30s
                        if media and media["length"] > 0:
                            seek_target = max(0, display_pos - 30)
                            seek_time = time.time()
                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", "30-"])
                    elif ord('0') <= key <= ord('9'):
                        # Jump directly to track percentage (0% to 90%)
                        if media and media["length"] > 0:
                            pct = (key - ord('0')) * 0.10
                            target = int(media["length"] * pct)
                            seek_target = target
                            seek_time = time.time()
                            fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", str(target)])
                    elif key in (ord('s'), ord('S'), ord(':'), ord('/')):
                        tgt = prompt_seek(stdscr, h, w, media)
                        if tgt is not None:
                            seek_target = tgt
                            seek_time = time.time()
                    elif key in (ord('k'), ord('K'), curses.KEY_UP):
                        vol_lock = (min(100, display_vol + 5), time.time())
                        fire_cmd(["${pkgs.wireplumber}/bin/wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"])
                    elif key in (ord('j'), ord('J'), curses.KEY_DOWN):
                        vol_lock = (max(0, display_vol - 5), time.time())
                        fire_cmd(["${pkgs.wireplumber}/bin/wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
                    elif key in (ord('m'), ord('M')):
                        fire_cmd(["${pkgs.wireplumber}/bin/wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
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

                            # Handle initial press on progress bar (time_row) or volume bar (vol_row)
                            if is_press and drag_mode is None:
                                if my == time_row and media and media["length"] > 0 and (12 <= mx <= 13 + b_width):
                                    drag_mode = 'progress'
                                    drag_val = int(media["length"] * x_to_ratio(mx, b_width))
                                    last_drag_time = now_m
                                    stdscr.timeout(20)
                                elif my == vol_row and (12 <= mx <= 13 + b_width):
                                    drag_mode = 'volume'
                                    drag_val = int(x_to_ratio(mx, b_width) * 100)
                                    last_drag_time = now_m
                                    stdscr.timeout(20)

                            # Handle active dragging (smooth real-time slider follow)
                            if drag_mode is not None and (is_motion or is_press):
                                last_drag_time = now_m
                                if drag_mode == 'progress' and media and media["length"] > 0:
                                    drag_val = int(media["length"] * x_to_ratio(mx, b_width))
                                elif drag_mode == 'volume':
                                    drag_val = int(x_to_ratio(mx, b_width) * 100)
                                    if now_m - last_vol_cmd > 0.08:
                                        last_vol_cmd = now_m
                                        fire_cmd(["${pkgs.wireplumber}/bin/wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", f"{drag_val}%"])

                            # Handle release / click commit
                            if is_release and drag_mode is not None:
                                last_drag_time = now_m
                                if drag_mode == 'progress' and media and media["length"] > 0:
                                    drag_val = int(media["length"] * x_to_ratio(mx, b_width))
                                    seek_target = drag_val
                                    seek_time = now_m
                                    fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", str(drag_val)])
                                elif drag_mode == 'volume':
                                    drag_val = int(x_to_ratio(mx, b_width) * 100)
                                    vol_lock = (drag_val, now_m)
                                    fire_cmd(["${pkgs.wireplumber}/bin/wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", f"{drag_val}%"])
                                drag_mode = None
                                stdscr.timeout(35)
                                curses.flushinp()
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
