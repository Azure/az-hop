import {test, expect} from '@playwright/test';
import azhopConfig from './azhop.config';

test('Grafana', async ({ browser }) => {

    // create context with HTTP credentials
    const context = await browser.newContext();

    // if grafan is enabled then browse to the UI
    if (azhopConfig.monitoring.grafana) {
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
    }
    // Close the browser
    await context.close();
  });
