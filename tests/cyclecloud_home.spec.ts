import {test, expect} from '@playwright/test';
import azhopConfig from './azhop.config';

test('CycleCloud', async ({browser}) => {
    // create context with HTTP credentials
    const context = await browser.newContext();

    // Open CycleCloud
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });
    await page.getByRole('button', { name: 'Monitoring' }).click();
    const page1Promise = page.waitForEvent('popup');
    await page.getByRole('link', { name: 'Azure CycleCloud' }).click();
    const page1 = await page1Promise;

    // Read the queue manager from the config file
    switch (azhopConfig.queue_manager) {
        case 'slurm':
            await page1.getByRole('tab', { name: 'slurm1' }).click();
            break;
        case 'openpbs':
            await page1.getByRole('tab', { name: 'pbs1' }).click();
            break;
    }
    await page1.waitForLoadState('networkidle');
    // Click text=Arrays
    await page1.click('text=Arrays');
    // Click #CloudStatus-NodeArraysTable-tbody >> text=execute
    await page1.click('#CloudStatus-NodeArraysTable-tbody >> text=execute');

    // Click text=Activity
    await page1.click('text=Activity');

    // Click text=Monitoring
    //await page.click('text=Monitoring');

    await page1.close()

    // Close the browser
    await context.close();
});
