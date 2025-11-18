/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        wood: {
          oak: '#C19A6B',
          walnut: '#5C4033',
          maple: '#D7C9AA',
          cherry: '#C95A49',
          pine: '#E4D5B7',
          mahogany: '#420D09',
        },
      },
    },
  },
  plugins: [],
}
