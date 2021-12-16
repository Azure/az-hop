import {test, expect} from '@playwright/test';

test('home page', async ({browser}) => {
    // create context with HTTP credentials
    const context = await browser.newContext();
    // Create a page
    const page = await context.newPage();
    await page.goto('/', { waitUntil: 'networkidle' });
    //await page.screenshot({path: 'home.png', fullPage: true});
    //await expect(page).toHaveTitle(/Getting started/);
    
    // Click text=Clusters
    await page.click('text=Clusters');

    // Click text=AZHOP - Cluster Shell Access
    const [page1] = await Promise.all([
        page.waitForEvent('popup'),
        page.click('text=AZHOP - Cluster Shell Access')
    ]);
    await page1.waitForLoadState('networkidle');
    //await page1.screenshot({path: 'shell.png', fullPage: true});
    await page1.close()

    // Open CycleCloud
    const page2 = await context.newPage();
    await page2.goto('/cyclecloud/home', { waitUntil: 'networkidle' });
    //await page2.screenshot({path: 'cyclecloud.png', fullPage: true});
    await page2.close()

    // Open Grafanna
    const page3 = await context.newPage();
    await page3.goto('/rnode/grafana/3000', { waitUntil: 'networkidle' });
    //await page3.screenshot({path: 'grafana.png', fullPage: true});
    await page3.close()

    // Close the browser
    await browser.close()
});



