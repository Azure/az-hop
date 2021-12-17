import {test, expect} from '@playwright/test';

test('Grafana', async ({browser}) => {
    // create context with HTTP credentials
    const context = await browser.newContext();

    // Open Grafanna
    const page = await context.newPage();
    await page.goto('/rnode/grafana/3000', { waitUntil: 'networkidle' });

    // Click [aria-label="Dashboards"] div
    await page.click('[aria-label="Dashboards"] div');
    // Click text=Browse >> [data-testid="dropdown-child-icon"]
    await page.click('text=Browse >> [data-testid="dropdown-child-icon"]');
    // Click text=dashboards| Go to folder
    await page.click('text=dashboards| Go to folder');

    // Click text=azhop - Infra Servers
    await Promise.all([
        page.waitForNavigation({ waitUntil: 'networkidle' }),
        page.click('text=azhop - Infra Servers')
    ]);

    await page.close()

    // Close the browser
    await context.close();
});



