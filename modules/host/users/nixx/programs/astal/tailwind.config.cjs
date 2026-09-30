let theme;
try {
  theme = require("./src/theme.json");
} catch (_) {
  theme = {
    hex: {
      bg: "#000000",
      surfaceMuted: "#0f172a",
      surfaceBorder: "#1e293b",
      text: "#f8fafc",
      accentLight: "#34d399",
      accent: "#10b981",
      accentTeal: "#5eead4",
    },
  };
}

module.exports = {
  corePlugins: {
    preflight: false,
    visibility: false,
    display: false,
    textOpacity: false,
    backgroundOpacity: false,
    borderOpacity: false,
    ringOpacity: false,
    height: false,
    maxHeight: false,
    minHeight: false,
    width: false,
    maxWidth: false,
    minWidth: false,
    flex: false,
    flexDirection: false,
    flexWrap: false,
    flexGrow: false,
    flexShrink: false,
    alignItems: false,
    alignContent: false,
    alignSelf: false,
    justifyContent: false,
    justifyItems: false,
    justifySelf: false,
    gap: false,
    textAlign: false,
  },
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
    "./app.ts",
  ],
  theme: {
    extend: {
      colors: {
        slate: {
          950: theme.hex.bg,
          900: theme.hex.surfaceMuted,
          800: theme.hex.surfaceBorder,
          200: theme.hex.text,
        },
        emerald: {
          400: theme.hex.accentLight,
          500: theme.hex.accent,
        },
        teal: {
          300: theme.hex.accentTeal,
        },
      },
    },
  },
  plugins: [],
}
