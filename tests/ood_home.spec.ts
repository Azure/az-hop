import {test, expect} from '@playwright/test';
import config from './playwright.config';

test('home page', async ({browser}) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });

    // Click text=Azure HPC On-Demand Platform
    await page.click('text=Azure HPC On-Demand Platform');
    expect(page.url()).toBe(config.use.baseURL + '/pun/sys/dashboard/');

    // Close the browser
    await context.close();
});

test('Shell Session', async ({browser}) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });

    // Click text=Clusters
    await page.click('text=Clusters');

    // Click text=AZHOP - Cluster Shell Access
    const [page1] = await Promise.all([
        page.waitForEvent('popup'),
        page.click('text=AZHOP - Cluster Shell Access')
    ]);

    await page1.waitForLoadState('networkidle');
    await page1.waitForTimeout(5000); // this delay is to allow the shell session to open in the frame
    // Click text=[hpcuser@ondemand ~]$
    const frame = page1.frame({
        url: 'about:blank'
    })
    await frame.waitForLoadState();
    const line = frame.locator('text=['+process.env.AZHOP_USER+'@ondemand ~]$');
    await line.click();

    await page.close()
    // Close the browser
    await context.close();
});

