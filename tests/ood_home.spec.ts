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

    await page.getByRole('button', { name: 'Clusters' }).click();
    const page1Promise = page.waitForEvent('popup');
    await page.getByRole('link', { name: 'AZHOP - Cluster Shell Access', exact: true }).click();
    const page1 = await page1Promise;
    await page1.frameLocator('iframe').getByText(process.env.AZHOP_USER+'@ondemand').click();
  
    await page.close()
    // Close the browser
    await context.close();
});

