{ self, inputs, ... }: {
  flake.homeModules.packages =
    { pkgs, ... }:
    let
      nixMatrix = pkgs.writeScriptBin "nix-matrix" ''
        #!${pkgs.python3}/bin/python3
        import curses
        import random
        import sys
        import time
        import subprocess

        BANNER_DEFAULT = [
            r"    _   _______  __",
            r"   / | / /  _/ |/ /",
            r"  /  |/ // / |   / ",
            r" / /|  // / /   |  ",
            r"/_/ |_/___//_/|_|  "
        ]

        def run(stdscr, banner_lines):
            curses.curs_set(0)
            curses.start_color()
            curses.use_default_colors()

            # Color pairs: 1: Green, 2: Bold White, 3: Cyan
            curses.init_pair(1, curses.COLOR_GREEN, -1)
            curses.init_pair(2, curses.COLOR_WHITE, -1)
            curses.init_pair(3, curses.COLOR_CYAN, -1)

            stdscr.nodelay(True)
            stdscr.timeout(45)

            chars = [chr(i) for i in range(0x30A0, 0x30FF)] + list("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ+=*~<>-_")
            max_y, max_x = stdscr.getmaxyx()

            class Stream:
                def __init__(self, x):
                    self.x = x
                    self.reset()
                    self.y = random.randint(-max_y, 0)

                def reset(self):
                    self.y = 0
                    self.speed = random.choice([1, 1, 1, 2])
                    self.length = random.randint(8, max(12, max_y - 4))

            streams = [Stream(x) for x in range(0, max_x, 2)]

            b_h = len(banner_lines)
            b_w = max(len(line) for line in banner_lines) if banner_lines else 0

            color_theme = 1
            paused = False

            while True:
                key = stdscr.getch()
                if key in [ord("q"), ord("Q"), 27]:
                    break
                elif key in [ord("p"), ord("P"), 32]:
                    paused = not paused
                elif key in [ord("c"), ord("C")]:
                    color_theme = 3 if color_theme == 1 else (2 if color_theme == 3 else 1)

                new_y, new_x = stdscr.getmaxyx()
                if new_y != max_y or new_x != max_x:
                    max_y, max_x = new_y, new_x
                    stdscr.clear()
                    streams = [Stream(x) for x in range(0, max_x, 2)]

                b_y = max(1, (max_y - b_h) // 2)
                b_x = max(1, (max_x - b_w) // 2)

                pad_y = 1
                pad_x = 2
                box_top = b_y - pad_y
                box_bottom = b_y + b_h + pad_y
                box_left = b_x - pad_x
                box_right = b_x + b_w + pad_x

                if not paused:
                    for s in streams:
                        for _ in range(s.speed):
                            lead_y = s.y
                            tail_y = s.y - s.length

                            if 0 <= tail_y < max_y:
                                if not (box_top <= tail_y <= box_bottom and box_left <= s.x <= box_right):
                                    try:
                                        stdscr.addch(tail_y, s.x, " ")
                                    except curses.error:
                                        pass

                            if 0 <= lead_y < max_y:
                                if not (box_top <= lead_y <= box_bottom and box_left <= s.x <= box_right):
                                    try:
                                        ch = random.choice(chars)
                                        stdscr.addch(lead_y, s.x, ch, curses.color_pair(2) | curses.A_BOLD)
                                    except curses.error:
                                        pass

                            fade_y = lead_y - 1
                            if 0 <= fade_y < max_y:
                                if not (box_top <= fade_y <= box_bottom and box_left <= s.x <= box_right):
                                    try:
                                        ch = random.choice(chars)
                                        stdscr.addch(fade_y, s.x, ch, curses.color_pair(color_theme))
                                    except curses.error:
                                        pass

                            s.y += 1
                            if s.y - s.length > max_y:
                                s.reset()

                # Render persistent centered ASCII banner
                for r_i, line in enumerate(banner_lines):
                    try:
                        stdscr.addstr(b_y + r_i, b_x, line, curses.color_pair(2) | curses.A_BOLD)
                    except curses.error:
                        pass

                stdscr.refresh()

        def main():
            text = sys.argv[1] if len(sys.argv) > 1 else "NIX"
            try:
                out = subprocess.check_output(["${pkgs.figlet}/bin/figlet", "-f", "slant", text]).decode("utf-8")
                banner = [line for line in out.splitlines() if line.strip()]
            except Exception:
                banner = BANNER_DEFAULT

            curses.wrapper(lambda scr: run(scr, banner))

        if __name__ == "__main__":
            main()
      '';
    in
    {
      # User packages that do not require dedicated module configuration
      home.packages = with pkgs; [
        yt-dlp
        antigravity-cli
        grim
        slurp
        satty
        wl-clipboard
        libnotify
        pavucontrol
        tty-clock
        nixMatrix
      ];
    };
}
