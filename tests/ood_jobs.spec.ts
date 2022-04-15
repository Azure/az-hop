import {test, expect} from '@playwright/test';
import config from './playwright.config';

test('Job Composer', async ({browser}) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });

    // Click text=Jobs
    await page.click('text=Jobs');

    // Click text=Job Composer
    const [page1] = await Promise.all([
        page.waitForEvent('popup'),
        page.click('text=Job Composer')
    ]);

    await page1.waitForLoadState('networkidle');
    await page1.close()

    // Close the browser
    await context.close();
});

test('Active Jobs', async ({browser}) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });

    // Click text=Jobs
    await page.click('text=Jobs');

    // Click text=Active Jobs
    await Promise.all([
        page.waitForNavigation({ waitUntil: 'networkidle' }),
        page.click('text=Active Jobs')
    ]);

    await page.waitForLoadState('networkidle');
    await page.close()
    
    // Close the browser
    await context.close();
});

