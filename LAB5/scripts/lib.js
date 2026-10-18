// Hàm dùng chung cho các action WebGUI pfSense
async function setVal(page, sel, v) {
  await page.$eval(sel, (e, v) => { e.value = v; e.dispatchEvent(new Event('change', { bubbles: true })); }, v);
}

// Liệt kê rule trên tab: [{id, descr, disabled}]
async function listRules(page, h, iface) {
  await page.goto(`${h.BASE}/firewall_rules.php?if=${iface}`);
  return page.$$eval('tbody.user-entries tr', trs => trs.map(tr => {
    const a = tr.querySelector('a[href*="firewall_rules_edit.php"][href*="id="]');
    const id = a ? new URL(a.href).searchParams.get('id') : null;
    const tds = [...tr.querySelectorAll('td')];
    return { id, descr: (tds[tds.length - 2]?.innerText || '').trim(), disabled: tr.classList.contains('disabled') };
  }).filter(r => r.id !== null));
}

// r: {iface, type, proto, srctype, src, dsttype, dst, port, log, descr, top}
async function addRule(page, h, r) {
  const q = r.top ? '&after=-1' : (r.after !== undefined ? `&after=${r.after}` : '');
  await page.goto(`${h.BASE}/firewall_rules_edit.php?if=${r.iface}${q}`);
  await page.selectOption('#type', r.type || 'pass');
  await page.selectOption('#ipprotocol', 'inet');
  await page.selectOption('#proto', r.proto || 'any');
  await page.selectOption('#srctype', r.srctype || 'any');
  if (r.src) await setVal(page, '#src', r.src);
  if (r.srcmask) await setVal(page, '#srcmask', r.srcmask);
  await page.selectOption('#dsttype', r.dsttype || 'any');
  if (r.dst) await setVal(page, '#dst', r.dst);
  if (r.port) {
    await setVal(page, '#dstbeginport', '');
    await setVal(page, '#dstbeginport_cust', r.port);
    await setVal(page, '#dstendport', '');
    await setVal(page, '#dstendport_cust', r.port);
  }
  if (r.log) await page.check('#log');
  await page.fill('#descr', r.descr);
  if (r.shot) await h.shot(page, r.shot);
  await page.waitForTimeout(1500); // tracker = time(): tránh 2 rule trùng tracker
  await Promise.all([page.waitForLoadState(), page.click('#save')]);
  const err = await page.locator('.alert-danger').allInnerTexts();
  if (err.length) throw new Error('Lỗi lưu rule: ' + err.join(' | '));
}

// Bật/tắt rule theo mô tả (regex) trên tab
async function setDisabled(page, h, iface, re, disabled) {
  const rules = await listRules(page, h, iface);
  const hit = rules.filter(r => re.test(r.descr));
  if (!hit.length) throw new Error('Không thấy rule ' + re);
  for (const r of hit) {
    if (r.disabled === disabled) continue;
    await page.goto(`${h.BASE}/firewall_rules_edit.php?if=${iface}&id=${r.id}`);
    if (disabled) await page.check('#disabled'); else await page.uncheck('#disabled');
    await Promise.all([page.waitForLoadState(), page.click('#save')]);
  }
}

async function applyRules(page, h, iface) {
  await page.goto(`${h.BASE}/firewall_rules.php?if=${iface}`);
  await h.apply(page);
}

async function resetStates(page, h, shotName) {
  await page.goto(`${h.BASE}/diag_resetstate.php`);
  await page.waitForTimeout(800);
  if (shotName) await h.shot(page, shotName);
  await page.locator('#statetable').check().catch(() => {});
  await page.locator('#Submit').click({ noWaitAfter: true, timeout: 5000 }).catch(() => {});
  await page.waitForTimeout(6000);
  for (let i = 0; i < 5; i++) {
    try { await page.goto(`${h.BASE}/diag_resetstate.php`, { timeout: 10000 }); break; } catch (e) { await page.waitForTimeout(3000); }
  }
}

async function deleteRules(page, h, iface, re) {
  const rules = await listRules(page, h, iface);
  const hit = rules.filter(r => re.test(r.descr));
  if (!hit.length) return;
  for (const r of hit) await page.check(`input[name="rule[]"][value="${r.id}"]`);
  await Promise.all([page.waitForLoadState(), page.click('#del_x')]);
}

module.exports = { deleteRules, setVal, listRules, addRule, setDisabled, applyRules, resetStates };
