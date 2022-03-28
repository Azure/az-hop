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
    // Click text=[hpcuser@ondemand ~]$
    await page1.frame({
        url: 'about:blank'
    }).click('text=['+process.env.AZHOP_USER+'@ondemand ~]$');

    await page.close()
    // Close the browser
    await context.close();
});

