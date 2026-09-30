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
        import subprocess
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

        def prompt_seek(stdscr, h, w, media):
            prompt = "Seek to (e.g. 1:30, 45, +15s, 50%): "
            py = min(h - 1, 9)
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
            stdscr.timeout(500)
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
                curses.mousemask(curses.BUTTON1_CLICKED | curses.BUTTON1_PRESSED | curses.BUTTON1_RELEASED)
            except Exception:
                pass
            stdscr.timeout(500)
            curses.start_color()
            curses.use_default_colors()

            curses.init_pair(1, curses.COLOR_CYAN, -1)
            curses.init_pair(2, curses.COLOR_GREEN, -1)
            curses.init_pair(3, curses.COLOR_MAGENTA, -1)
            curses.init_pair(4, curses.COLOR_RED, -1)
            curses.init_pair(5, curses.COLOR_YELLOW, -1)

            seek_target = None
            seek_time = 0.0
            vol_lock = None
            last_mouse_time = 0.0

            while True:
                now = time.time()
                h, w = stdscr.getmaxyx()
                
                # Fetch state first before erasing screen buffer
                media = get_media()
                vol, muted = get_volume()

                # Smooth display position: prevent jumping when player updates position asynchronously
                display_pos = media["pos"] if media else 0
                if seek_target is not None:
                    if now - seek_time < 1.0:
                        if abs((media["pos"] if media else 0) - seek_target) > 3:
                            display_pos = seek_target
                        else:
                            seek_target = None
                    else:
                        seek_target = None

                # Smooth display volume
                display_vol = vol
                if vol_lock is not None:
                    if now - vol_lock[1] < 0.8:
                        display_vol = vol_lock[0]
                    else:
                        vol_lock = None

                stdscr.erase()

                # Render Header
                title_str = " 🎵 MEDIA & AUDIO CONTROLLER "
                safe_addstr(stdscr, 1, max(0, (w - len(title_str)) // 2), title_str, curses.color_pair(3) | curses.A_BOLD)
                safe_addstr(stdscr, 2, 2, "─" * max(0, w - 4), curses.color_pair(1))

                # Media Info
                b_width = max(10, min(28, w - 32))
                if media:
                    stat_icon = "▶" if media["status"] == "Playing" else ("⏸" if media["status"] == "Paused" else "⏹")
                    stat_color = curses.color_pair(2) if media["status"] == "Playing" else curses.color_pair(5)
                    
                    safe_addstr(stdscr, 3, 3, "Player : ", curses.A_BOLD)
                    safe_addstr(stdscr, 3, 12, f"{media['player'].capitalize()} [{stat_icon} {media['status']}]", stat_color | curses.A_BOLD)

                    safe_addstr(stdscr, 4, 3, "Track  : ", curses.A_BOLD)
                    safe_addstr(stdscr, 4, 12, media['title'] or 'Unknown Title', curses.A_BOLD)

                    safe_addstr(stdscr, 5, 3, "Artist : ", curses.A_BOLD)
                    safe_addstr(stdscr, 5, 12, media['artist'] or 'Unknown Artist', curses.color_pair(1))

                    safe_addstr(stdscr, 6, 3, "Time   : ", curses.A_BOLD)
                    if media["length"] > 0:
                        prog_bar = f"[{bar(display_pos, media['length'], b_width)}]"
                        time_str = f" {fmt_time(display_pos)} / {fmt_time(media['length'])}"
                        safe_addstr(stdscr, 6, 12, prog_bar)
                        safe_addstr(stdscr, 6, 12 + len(prog_bar), time_str, curses.color_pair(2))
                    else:
                        safe_addstr(stdscr, 6, 12, f"{fmt_time(display_pos)} (Live stream / unknown length)", curses.A_DIM)
                else:
                    safe_addstr(stdscr, 3, 3, "Player : ", curses.A_BOLD)
                    safe_addstr(stdscr, 3, 12, "Idle", curses.A_DIM)
                    safe_addstr(stdscr, 4, 3, "Track  : ", curses.A_BOLD)
                    safe_addstr(stdscr, 4, 12, "No active MPRIS player detected", curses.color_pair(5))
                    safe_addstr(stdscr, 5, 3, "Artist : ", curses.A_BOLD)
                    safe_addstr(stdscr, 5, 12, "(Start Spotify, Zen Browser, or MPV)", curses.A_DIM)
                    safe_addstr(stdscr, 6, 3, "Time   : ", curses.A_BOLD)
                    safe_addstr(stdscr, 6, 12, "--:-- / --:--", curses.A_DIM)

                # Volume Info
                vol_icon = "🔇 MUTED" if muted else f"🔊 {display_vol}%"
                vol_color = curses.color_pair(4) if muted else curses.color_pair(2)
                safe_addstr(stdscr, 7, 3, "Volume : ", curses.A_BOLD)
                vol_bar = f"[{bar(display_vol, 100, b_width)}]"
                safe_addstr(stdscr, 7, 12, vol_bar)
                safe_addstr(stdscr, 7, 12 + len(vol_bar), f" {vol_icon}", vol_color | curses.A_BOLD)

                # Controls Footer
                ctrl_y1 = max(9, h - 3)
                ctrl_y2 = ctrl_y1 + 1
                safe_addstr(stdscr, ctrl_y1 - 1, 2, "─" * max(0, w - 4), curses.color_pair(1))
                ctrls1 = "[Space] Play/Pause   [u/i] Prev/Next Track   [h/l] Seek ±10s   [0-9] %"
                ctrls2 = "[j/k] Vol ±5%        [s] Seek to...          [m] Mute          [q] Quit"
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
                        if bstate & (curses.BUTTON1_CLICKED | curses.BUTTON1_PRESSED | curses.BUTTON1_RELEASED):
                            now_m = time.time()
                            if now_m - last_mouse_time >= 0.15:
                                last_mouse_time = now_m
                                curses.flushinp()

                                # Mouse click on progress bar (line 6)
                                if my == 6 and media and media["length"] > 0:
                                    if 12 <= mx <= 13 + b_width:
                                        if mx <= 13:
                                            ratio = 0.0
                                        elif mx >= 12 + b_width:
                                            ratio = 1.0
                                        else:
                                            ratio = (mx - 13) / max(1, b_width - 1)
                                        target = int(media["length"] * ratio)
                                        seek_target = target
                                        seek_time = now_m
                                        fire_cmd(["${pkgs.playerctl}/bin/playerctl", "position", str(target)])

                                # Mouse click on volume bar (line 7)
                                elif my == 7:
                                    if 12 <= mx <= 13 + b_width:
                                        if mx <= 13:
                                            ratio = 0.0
                                        elif mx >= 12 + b_width:
                                            ratio = 1.0
                                        else:
                                            ratio = (mx - 13) / max(1, b_width - 1)
                                        target_vol = int(ratio * 100)
                                        vol_lock = (target_vol, now_m)
                                        target_pct = f"{target_vol}%"
                                        fire_cmd(["${pkgs.wireplumber}/bin/wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", target_pct])
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
