import {test, expect} from '@playwright/test';
import config from './playwright.config';

// test('Windows Desktop', async ({browser}) => {
//     // create context with HTTP credentials
//     const context = await browser.newContext();
//     // Create a page
//     const page = await context.newPage();
//     await page.goto('/', { waitUntil: 'networkidle' });

//     // Click text=Interactive Apps
//     await page.click('text=Interactive Apps');

//     // Click div[role="main"] >> text=Windows Desktop
//     await page.click('div[role="main"] >> text=Windows Desktop');

//     // Click input:has-text("Launch")
//     await page.click('input:has-text("Launch")');

//     // Click a:has-text("Delete")
//     await page.click('a:has-text("Delete")');

//     // Click text=Confirm
//     await page.click('text=Confirm');

//     await page.waitForLoadState('networkidle');
//     await page.close()
    
//     // Close the browser
//     await context.close();
// });

test('Linux Desktop', async ({ browser }) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });

    await page.getByRole('button', { name: 'Interactive Apps' }).click();
    await page.getByRole('listitem', { name: 'Interactive Apps' }).getByRole('link', { name: 'Linux Desktop' }).click();
    await page.getByRole('combobox', { name: 'Session target' }).selectOption('largeviz3d');
    await page.getByRole('combobox', { name: 'Session target' }).selectOption('viz3d');
    await page.getByLabel('Maximum duration in hours of your remote session').click();
    await page.getByLabel('Maximum duration in hours of your remote session').fill('1');
    await page.getByLabel('Maximum duration in hours of your remote session').press('Tab');
    await page.getByRole('button', { name: 'Launch' }).click();
    await page.getByRole('link', { name: ' Delete' }).click();
    await page.getByRole('button', { name: 'Confirm' }).click();

    await page.waitForLoadState('networkidle');
    await page.close()

    // Close the browser
    await context.close();
  });

test('CodeServer', async ({ browser }) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });

    await page.getByRole('button', { name: 'Interactive Apps' }).click();
    await page.getByRole('link', { name: 'Code Server', exact: true }).click();
    await page.getByRole('combobox', { name: 'Slot Type' }).selectOption('hb120v2');
    await page.getByRole('combobox', { name: 'Slot Type' }).selectOption('execute');
    await page.getByRole('button', { name: 'Launch' }).click();
    await page.getByRole('link', { name: ' Delete' }).click();
    await page.getByRole('button', { name: 'Confirm' }).click();

    await page.waitForLoadState('networkidle');
    await page.close()

    // Close the browser
    await context.close();
  });
