/** @type {import('tailwindcss').Config} */
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
          950: "#020617",
          900: "#0f172a",
          800: "#1e293b",
          200: "#e2e8f0",
        },
        emerald: {
          400: "#34d399",
          500: "#10b981",
        },
        teal: {
          300: "#5eead4",
        },
      },
    },
  },
  plugins: [],
}
