import { PlaywrightTestConfig } from '@playwright/test';
const config: PlaywrightTestConfig = {
//    testDir: './tests',
    /* Maximum time one test can run for. */
    timeout: 120 * 1000,
    /* Retry on CI only */
    retries: process.env.CI ? 2 : 0,
    /* Opt out of parallel tests on CI. */
    workers: process.env.CI ? 1 : undefined,
    globalTimeout: 60 * 60 * 1000,
    snapshotDir: './snapshots', 
    reporter: process.env.CI ? 'html' : 'dot',
    use: {
        headless: true,
        baseURL: process.env.AZHOP_FQDN,
        ignoreHTTPSErrors: true,
        viewport: { width: 1600, height: 900 },
        screenshot: 'only-on-failure',
        httpCredentials: {
            username: process.env.AZHOP_USER,
            password: process.env.AZHOP_PASSWORD
        },
        trace: 'on-first-retry',
        launchOptions: {
            args: ['--window-position=-100,-100', '--window-size=1600,900', '--start-maximized']
        }
    },
};
export default config;
//browser = playwright.chromium.launch(args=['--window-position=-5,-5'],headless=False)