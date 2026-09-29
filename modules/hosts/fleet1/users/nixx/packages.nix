{ self, inputs, ... }: {
  flake.homeModules.packages =
    { pkgs, ... }:
    let
      nixMatrix = pkgs.writeScriptBin "nix-matrix" ''
        #!${pkgs.python3}/bin/python3
        import curses
        import random
        import sys
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

        # Half-width Katakana (U+FF66 - U+FF9D): strictly 1 cell wide, native Matrix font
        KATAKANA_HALFWIDTH = [chr(i) for i in range(0xFF66, 0xFF9E)]
        GLYPHS = list("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ:=+-*~<>|!$#@")
        MATRIX_CHARS = KATAKANA_HALFWIDTH + GLYPHS

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
            try:
                curses.curs_set(0)
            except Exception:
                pass
            curses.start_color()
            curses.use_default_colors()

            # Color pairs: 1: Green, 2: Bold White, 3: Cyan
            curses.init_pair(1, curses.COLOR_GREEN, -1)
            curses.init_pair(2, curses.COLOR_WHITE, -1)
            curses.init_pair(3, curses.COLOR_CYAN, -1)

            stdscr.nodelay(True)
            stdscr.timeout(45)

            max_y, max_x = stdscr.getmaxyx()

            is_filled = initial_filled
            banner_lines = get_banner(text, is_filled)

            color_theme = 1
            paused = False

            class Stream:
                def __init__(self, x, max_y, box_bounds):
                    self.x = x
                    self.box_bounds = box_bounds
                    self.reset(max_y, initial=True)

                def reset(self, max_y, initial=False):
                    self.speed = random.choice([1, 1, 2])
                    self.length = random.randint(8, max(12, max_y - 4))
                    b_top, b_bottom, b_left, b_right = self.box_bounds
                    in_banner_col = (b_left <= self.x <= b_right)

                    if in_banner_col:
                        # Stream either falls above banner or starts below banner
                        if random.random() < 0.5:
                            self.zone = "top"
                            self.limit_y = b_top
                            self.y = random.randint(-self.length, 0) if initial else 0
                        else:
                            self.zone = "bottom"
                            self.limit_y = max_y
                            self.y = (b_bottom + 1) if not initial else random.randint(b_bottom + 1, max_y)
                    else:
                        self.zone = "full"
                        self.limit_y = max_y
                        self.y = random.randint(-max_y, 0) if initial else 0

            def compute_box(b_lines, my, mx):
                bh = len(b_lines)
                bw = max(len(l) for l in b_lines) if b_lines else 0
                by = max(1, (my - bh) // 2)
                bx = max(1, (mx - bw) // 2)
                return (by - 1, by + bh, bx - 2, bx + bw + 1, by, bx, bh, bw)

            box_top, box_bottom, box_left, box_right, b_y, b_x, b_h, b_w = compute_box(banner_lines, max_y, max_x)
            box_bounds = (box_top, box_bottom, box_left, box_right)

            streams = [Stream(x, max_y, box_bounds) for x in range(0, max_x, 2)]

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
                    box_top, box_bottom, box_left, box_right, b_y, b_x, b_h, b_w = compute_box(banner_lines, max_y, max_x)
                    box_bounds = (box_top, box_bottom, box_left, box_right)
                    for s in streams:
                        s.box_bounds = box_bounds

                new_y, new_x = stdscr.getmaxyx()
                if new_y != max_y or new_x != max_x:
                    max_y, max_x = new_y, new_x
                    stdscr.clear()
                    box_top, box_bottom, box_left, box_right, b_y, b_x, b_h, b_w = compute_box(banner_lines, max_y, max_x)
                    box_bounds = (box_top, box_bottom, box_left, box_right)
                    streams = [Stream(x, max_y, box_bounds) for x in range(0, max_x, 2)]

                if not paused:
                    for s in streams:
                        for _ in range(s.speed):
                            lead_y = s.y
                            tail_y = s.y - s.length

                            # Blank out old tail
                            if 0 <= tail_y < s.limit_y:
                                try:
                                    stdscr.addch(tail_y, s.x, " ")
                                except curses.error:
                                    pass

                            # Draw leading head character (bold white)
                            if 0 <= lead_y < s.limit_y:
                                try:
                                    ch = random.choice(MATRIX_CHARS)
                                    stdscr.addch(lead_y, s.x, ch, curses.color_pair(2) | curses.A_BOLD)
                                except curses.error:
                                    pass

                            # Fade previous head to green/cyan
                            fade_y = lead_y - 1
                            if 0 <= fade_y < s.limit_y:
                                try:
                                    ch = random.choice(MATRIX_CHARS)
                                    stdscr.addch(fade_y, s.x, ch, curses.color_pair(color_theme))
                                except curses.error:
                                    pass

                            s.y += 1
                            if s.y - s.length > s.limit_y:
                                s.reset(max_y)

                # Clear and render the protected banner box
                for r in range(box_top, box_bottom + 1):
                    for c in range(box_left, box_right + 1):
                        if 0 <= r < max_y and 0 <= c < max_x:
                            try:
                                stdscr.addch(r, c, " ")
                            except curses.error:
                                pass

                # Draw the centered banner in bold
                for r_i, line in enumerate(banner_lines):
                    row_y = b_y + r_i
                    if 0 <= row_y < max_y:
                        try:
                            stdscr.addstr(row_y, b_x, line, curses.color_pair(2) | curses.A_BOLD)
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
