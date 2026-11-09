import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

// Read host/port/API target from environment variables or use defaults
const webHost = process.env.CALLIOPE_WEB_HOST || '127.0.0.1';
const webPort = parseInt(process.env.CALLIOPE_WEB_PORT || '5173', 10);
const apiTarget = process.env.CALLIOPE_API_TARGET || 'http://127.0.0.1:8247';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		host: webHost,
		port: webPort,
		strictPort: true,
		proxy: {
			'/api': {
				target: apiTarget,
				changeOrigin: true,
			},
		},
	},
});
