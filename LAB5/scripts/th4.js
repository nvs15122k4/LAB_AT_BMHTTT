const lib = require('./lib');
module.exports = async (page, h) => {
  // Kiểm tra dịch vụ web DMZ đang lắng nghe
  await page.goto(h.BASE + '/diag_testport.php');
  await page.fill('#host', '172.16.0.2'); await page.fill('#port', '80'); await page.check('#showtext');
  await Promise.all([page.waitForLoadState(), page.click('#Submit')]);
  await page.waitForTimeout(1500);
  await h.shot(page, 'TH4a_TestPort_172.16.0.2_80');
  // WAN: bỏ Block private / bogon (chỉ trong lab)
  await page.goto(h.BASE + '/interfaces.php?if=wan');
  await page.uncheck('#blockpriv'); await page.uncheck('#blockbogons');
  await h.shot(page, 'TH4b_WAN_Bo_Block_Private_Bogon');
  await Promise.all([page.waitForLoadState(), page.click('#save')]);
  await h.apply(page);
  // Port Forward WAN:8080 -> 172.16.0.2:80
  await page.goto(h.BASE + '/firewall_nat_edit.php');
  await page.selectOption('#interface', 'wan');
  await page.selectOption('#proto', 'tcp');
  await page.selectOption('#dsttype', 'wanip');
  await lib.setVal(page, '#dstbeginport', ''); await lib.setVal(page, '#dstbeginport_cust', '8080');
  await lib.setVal(page, '#dstendport', ''); await lib.setVal(page, '#dstendport_cust', '8080');
  await page.fill('#localip', '172.16.0.2');
  await lib.setVal(page, '#localbeginport', ''); await lib.setVal(page, '#localbeginport_cust', '80');
  await page.fill('#descr', 'TH4 - Port Forward WAN:8080 -> DMZ-Web 172.16.0.2:80');
  await page.selectOption('#filter-rule-association', 'add-associated');
  await h.shot(page, 'TH4c_PortForward_Form');
  await Promise.all([page.waitForLoadState(), page.click('#save')]);
  const err = await page.locator('.alert-danger').allInnerTexts(); if (err.length) throw new Error(err.join('|'));
  await h.apply(page);
  await h.shot(page, 'TH4d_PortForward_List');
  await page.goto(h.BASE + '/firewall_rules.php?if=wan');
  await h.shot(page, 'TH4e_WAN_Rule_Associated');
  await lib.resetStates(page, h);
};
