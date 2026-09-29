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
        import argparse

        BANNER_SLANT = [
            r"    _   _______  __",
            r"   / | / /  _/ |/ /",
            r"  /  |/ // / |   / ",
            r" / /|  // / /   |  ",
            r"/_/ |_/___//_/|_|  "
        ]

        BANNER_FILLED = [
            "█     █ ███ █     █",
            "██    █  █   █   █ ",
            "█ █   █  █    █ █  ",
            "█  █  █  █     █   ",
            "█   █ █  █    █ █  ",
            "█    ██  █   █   █ ",
            "█     █ ███ █     █"
        ]

        def get_banner(text, filled):
            try:
                font = "banner" if filled else "slant"
                out = subprocess.check_output(["${pkgs.figlet}/bin/figlet", "-f", font, text]).decode("utf-8")
                lines = [line.rstrip() for line in out.splitlines() if line.strip()]
                if filled:
                    lines = [line.replace("#", "█") for line in lines]
                return lines
            except Exception:
                return BANNER_FILLED if filled else BANNER_SLANT

        def run(stdscr, text, initial_filled):
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

            is_filled = initial_filled
            banner_lines = get_banner(text, is_filled)

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
                elif key in [ord("f"), ord("F"), ord("b"), ord("B")]:
                    is_filled = not is_filled
                    banner_lines = get_banner(text, is_filled)
                    stdscr.clear()

                new_y, new_x = stdscr.getmaxyx()
                if new_y != max_y or new_x != max_x:
                    max_y, max_x = new_y, new_x
                    stdscr.clear()
                    streams = [Stream(x) for x in range(0, max_x, 2)]

                b_h = len(banner_lines)
                b_w = max(len(line) for line in banner_lines) if banner_lines else 0
                b_y = max(1, (max_y - b_h) // 2)
                b_x = max(1, (max_x - b_w) // 2)

                # Set of coordinates occupied by non-space banner glyphs
                banner_cells = set()
                for r_i, line in enumerate(banner_lines):
                    for c_i, ch in enumerate(line):
                        if ch != " ":
                            banner_cells.add((b_y + r_i, b_x + c_i))

                if not paused:
                    for s in streams:
                        for _ in range(s.speed):
                            lead_y = s.y
                            tail_y = s.y - s.length

                            if 0 <= tail_y < max_y:
                                if (tail_y, s.x) not in banner_cells:
                                    try:
                                        stdscr.addch(tail_y, s.x, " ")
                                    except curses.error:
                                        pass

                            if 0 <= lead_y < max_y:
                                if (lead_y, s.x) not in banner_cells:
                                    try:
                                        ch = random.choice(chars)
                                        stdscr.addch(lead_y, s.x, ch, curses.color_pair(2) | curses.A_BOLD)
                                    except curses.error:
                                        pass

                            fade_y = lead_y - 1
                            if 0 <= fade_y < max_y:
                                if (fade_y, s.x) not in banner_cells:
                                    try:
                                        ch = random.choice(chars)
                                        stdscr.addch(fade_y, s.x, ch, curses.color_pair(color_theme))
                                    except curses.error:
                                        pass

                            s.y += 1
                            if s.y - s.length > max_y:
                                s.reset()

                # Always render the banner characters in high contrast bold
                for (cell_y, cell_x) in banner_cells:
                    r_i = cell_y - b_y
                    c_i = cell_x - b_x
                    ch = banner_lines[r_i][c_i]
                    try:
                        stdscr.addstr(cell_y, cell_x, ch, curses.color_pair(2) | curses.A_BOLD)
                    except curses.error:
                        pass

                stdscr.refresh()

        def main():
            parser = argparse.ArgumentParser(description="Matrix digital rain with centered ASCII banner")
            parser.add_argument("text", nargs="?", default="NIX", help="Text to display in the banner")
            parser.add_argument("-f", "--filled", "-b", "--block", action="store_true", help="Use solid filled block characters (█)")
            args = parser.parse_args()

            curses.wrapper(lambda scr: run(scr, args.text, args.filled))

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
