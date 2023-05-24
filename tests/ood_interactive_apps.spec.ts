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

test('Linux Desktop', async ({browser}) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });

    // Click text=Interactive Apps
    await page.click('text=Interactive Apps');

    // Click div[role="main"] >> text=Linux Desktop
    await page.click('div[role="main"] >> text=Linux Desktop');

    // Click input[name="batch_connect_session_context\[hours\]"]
    await page.click('input[name="batch_connect_session_context\\[num_hours\\]"]');

    // Fill input[name="batch_connect_session_context\[hours\]"]
    await page.fill('input[name="batch_connect_session_context\\[num_hours\\]"]', '1');

    // Press Tab
    await page.press('input[name="batch_connect_session_context\\[num_hours\\]"]', 'Tab');

    // Click input:has-text("Launch")
    await page.click('input:has-text("Launch")');

    // Click text=Delete
    await page.click('text=Delete');

    // Click text=Confirm
    await page.click('text=Confirm');

    await page.waitForLoadState('networkidle');
    await page.close()
    
    // Close the browser
    await context.close();
});

test('CodeServer', async ({browser}) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });

    // Click text=Interactive Apps
    await page.click('text=Interactive Apps');

    // Click :nth-match(:text("Code Server"), 2)
    await page.click(':nth-match(:text("Code Server"), 2)');

    // Click input[name="batch_connect_session_context\[hours\]"]
    await page.click('input[name="batch_connect_session_context\\[hours\\]"]');

    // Fill input[name="batch_connect_session_context\[hours\]"]
    await page.fill('input[name="batch_connect_session_context\\[hours\\]"]', '1');

    // Press Tab
    await page.press('input[name="batch_connect_session_context\\[hours\\]"]', 'Tab');

    // Click input:has-text("Launch")
    await page.click('input:has-text("Launch")');

    // Click text=Delete
    await page.click('text=Delete');

    // Click text=Confirm
    await page.click('text=Confirm');

    await page.waitForLoadState('networkidle');
    await page.close()
    
    // Close the browser
    await context.close();
});

