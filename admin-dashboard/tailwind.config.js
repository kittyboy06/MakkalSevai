/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        civic: {
          navy: "#0F172A",
          surface: "#F8FAFC",
          card: "#FFFFFF",
          border: "#E2E8F0",
          emerald: "#059669",
          amber: "#D97706",
          crimson: "#DC2626",
          slate: "#64748B",
          blue: "#1E40AF"
        }
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'Inter', 'system-ui', 'sans-serif'],
        mono: ['ui-monospace', 'SFMono-Regular', 'Menlo', 'monospace']
      }
    },
  },
  plugins: [],
}
