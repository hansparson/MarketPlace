import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react()],
    server: {
        port: 3000,
        host: true,
        proxy: {
            '/api': {
                target: 'http://localhost:8080',
                changeOrigin: true,
            },
            '/wilayah-api': {
                target: 'https://wilayah.web.id/api',
                changeOrigin: true,
                rewrite: (path) => path.replace(/^\/wilayah-api/, ''),
                headers: {
                    Origin: 'https://wilayah.web.id',
                    Referer: 'https://wilayah.web.id/'
                }
            }
        }
    }
})
