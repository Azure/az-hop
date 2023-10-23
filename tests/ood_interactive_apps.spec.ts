import {test, expect} from '@playwright/test';
import config from './playwright.config';

test('Linux Desktop', async ({ browser }) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    page.on('dialog', dialog => dialog.accept());
    await page.goto('/', { waitUntil: 'networkidle' });

    await page.getByRole('button', { name: 'Interactive Apps' }).click();
    await page.getByRole('listitem', { name: 'Interactive Apps' }).getByRole('link', { name: 'Linux Desktop' }).click();
    await page.getByRole('combobox', { name: 'Session target' }).selectOption('largeviz3d');
    await page.getByRole('combobox', { name: 'Session target' }).selectOption('viz3d');
    await page.getByLabel('Maximum duration in hours of your remote session').click();
    await page.getByLabel('Maximum duration in hours of your remote session').fill('1');
    await page.getByLabel('Maximum duration in hours of your remote session').press('Tab');
    await page.getByRole('button', { name: 'Launch' }).click();

    await page.locator('#batch_connect_sessions div').filter({ hasText: /Linux Desktop/ }).getByRole('button', { name: 'Delete Linux Desktop Session' }).click();

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
    page.on('dialog', dialog => dialog.accept());
    await page.goto('/', { waitUntil: 'networkidle' });

    await page.getByRole('button', { name: 'Interactive Apps' }).click();
    await page.getByRole('link', { name: 'Code Server', exact: true }).click();
    await page.getByRole('combobox', { name: 'Slot Type' }).selectOption('hpc');
    await page.getByRole('combobox', { name: 'Slot Type' }).selectOption('htc');
    await page.getByRole('button', { name: 'Launch' }).click();
    await page.locator('#batch_connect_sessions div').filter({ hasText: /Code Server/ }).getByRole('button', { name: 'Delete Code Server Session' }).click();

    await page.waitForLoadState('networkidle');
    await page.close()

    // Close the browser
    await context.close();
  });
