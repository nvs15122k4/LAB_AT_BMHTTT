// fwlog.js <shot> [src] [dst] [proto] [iface]
module.exports = async (page, h, [shot, src, dst, proto, iface]) => {
  await page.goto(h.BASE + '/status_logs_settings.php');
  if (!(await page.isChecked('#reverse'))) {
    await page.check('#reverse');
    await Promise.all([page.waitForLoadState(), page.click('#save')]);
  }
  await page.goto(h.BASE + '/status_logs_filter.php');
  const set = async (n, v) => { if (v) await page.$eval('#filterlogentries_' + n, (e, v) => e.value = v, v); };
  await set('sourceipaddress', src); await set('destinationipaddress', dst);
  await set('protocol', proto); await set('interfaces', iface);
  if (src || dst || proto || iface)
    await Promise.all([page.waitForLoadState(), page.$eval('#filterlogentries_submit', b => b.click())]);
  await page.waitForTimeout(1500);
  await h.shot(page, shot, { fullPage: false });
  const rows = await page.$$eval('table tbody tr', trs => trs.slice(0, 8).map(t => t.innerText.replace(/\s+/g, ' ')));
  console.log(rows.join('\n'));
};
