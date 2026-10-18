// LAB5 - điều khiển WebGUI pfSense bằng Playwright (giữ phiên qua state.json)
// node pf.js <action-file.js> [args...]   — file action export async (page, ctx, args) => {}
const path = require('path');
const fs = require('fs');
const { chromium } = require(path.join(process.env.HOME, 'Downloads/node_modules/playwright'));

const BASE = process.env.PF_URL || 'https://10.0.0.1';
const STATE = path.join(__dirname, '..', 'logs', 'pf-state.json');
const IMG = path.join(__dirname, '..', 'images');

async function login(page) {
  await page.goto(BASE + '/index.php');
  if (await page.locator('#usernamefld').count()) {
    await page.fill('#usernamefld', 'admin');
    await page.fill('#passwordfld', process.env.PF_PASS || 'Lab5@Pfs2026');
    await Promise.all([page.waitForLoadState(), page.click('[name=login]')]);
  }
}

async function shot(page, name, opts = {}) {
  const file = path.join(IMG, name.endsWith('.png') ? name : name + '.png');
  await page.screenshot({ path: file, fullPage: opts.fullPage !== false });
  console.log('shot', file);
}

async function apply(page) {
  const btn = page.locator('button[name=apply], input[name=apply]');
  if (await btn.count()) {
    await Promise.all([page.waitForLoadState(), btn.first().click()]);
    await page.waitForTimeout(3000);
  }
}

async function resetStates(page) {
  await page.goto(BASE + '/diag_resetstate.php');
  page.once('dialog', d => d.accept());
  const btn = page.locator('button[name=Submit], button#Submit, button:has-text("Reset")');
  await btn.first().click().catch(() => {});
  await page.waitForTimeout(4000);
}

(async () => {
  const [actionFile, ...args] = process.argv.slice(2);
  const browser = await chromium.launch();
  const ctx = await browser.newContext({
    ignoreHTTPSErrors: true,
    viewport: { width: 1366, height: 860 },
    storageState: fs.existsSync(STATE) ? STATE : undefined,
  });
  const page = await ctx.newPage();
  page.on('dialog', d => d.accept());
  const helpers = { BASE, login, shot, apply, resetStates };
  try {
    if (!process.env.NOLOGIN) await login(page);
    const action = require(path.resolve(actionFile));
    await action(page, helpers, args);
  } catch (e) {
    console.error('ERROR', e.message);
    await page.screenshot({ path: path.join(__dirname, '..', 'logs', 'pf-error.png'), fullPage: true });
    process.exitCode = 1;
  } finally {
    await ctx.storageState({ path: STATE });
    await browser.close();
  }
})();
