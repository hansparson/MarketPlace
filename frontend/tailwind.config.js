/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            fontFamily: {
                sans: ['Inter', 'sans-serif'],
            },
            colors: {
                olx: {
                    cyan: '#23e5db',
                    dark: '#002f34',
                    gray: '#f2f4f5',
                }
            }
        },
    },
    plugins: [],
}
