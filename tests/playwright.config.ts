import { PlaywrightTestConfig } from '@playwright/test';
const config: PlaywrightTestConfig = {
    globalTimeout: 60 * 60 * 1000,
    snapshotDir: 'snapshots',
    reporter: process.env.CI ? 'github' : 'list',
    use: {
        headless: true,
        baseURL: process.env.AZHOP_FQDN,
        viewport: { width: 1600, height: 900 },
        screenshot: 'only-on-failure',
        httpCredentials: {
            username: process.env.AZHOP_USER,
            password: process.env.AZHOP_PASSWORD
        },
    },
};
export default config;