import {test, expect} from '@playwright/test';

// test('Grafana', async ({browser}) => {
//     // create context with HTTP credentials
//     const context = await browser.newContext();

//     // Open Grafana
//     const page = await context.newPage();
//     await page.goto('/rnode/grafana/3000', { waitUntil: 'networkidle' });

//     // Click [aria-label="Dashboards"] div
//     //await page.click('[aria-label="Dashboards"] div');
//     // Click text=Browse >> [data-testid="dropdown-child-icon"]
//     //await page.click('text=Browse >> [data-testid="dropdown-child-icon"]');

//     await page.goto('/rnode/grafana/3000/dashboards', { waitUntil: 'networkidle' });
//     // Click text=dashboards| Go to folder
//     await page.click('text=dashboards| Go to folder');

//     // Click text=azhop - Infra Servers
//     await Promise.all([
//         page.waitForNavigation({ waitUntil: 'networkidle' }),
//         page.click('text=azhop - Infra Servers')
//     ]);

//     await page.close()

//     // Close the browser
//     await context.close();
// });


test('Grafana', async ({ browser }) => {

    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });

    await page.getByRole('button', { name: 'Monitoring' }).click();
    const page1Promise = page.waitForEvent('popup');
    await page.getByRole('link', { name: 'Grafana Dashboard' }).click();
    const page1 = await page1Promise;
    await page1.getByRole('button', { name: 'Toggle menu' }).click();
    await page1.getByTestId('navbarmenu').getByRole('link', { name: 'Dashboards' }).click();
    await page1.getByTestId('data-testid Folder header dashboards').getByText('dashboards').click();
    await page1.getByRole('link', { name: 'azhop - Infra Servers' }).click();
    await page1.waitForLoadState('networkidle');
    await page1.getByTestId('data-testid Dashboard template variables Variable Value DropDown value link text ondemand').click();
    await page1.getByRole('checkbox', { name: 'ccportal' }).click();

    await page1.waitForLoadState('networkidle');
    await page1.close()

    // Close the browser
    await context.close();
  });
