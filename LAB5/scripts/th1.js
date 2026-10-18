const lib = require('./lib');
module.exports = async (page, h) => {
  // Alias cổng web 80, 443
  await page.goto(h.BASE + '/firewall_aliases_edit.php?tab=port');
  await page.fill('#name', 'WEB_PORTS');
  await page.fill('#descr', 'LAB5 HTTP/HTTPS');
  await page.fill('#address0', '80'); await page.fill('#detail0', 'HTTP');
  await page.click('#addrow');
  await page.fill('#address1', '443'); await page.fill('#detail1', 'HTTPS');
  await Promise.all([page.waitForLoadState(), page.click('#save')]);
  await h.apply(page);
  await h.shot(page, 'TH1a_Alias_WEB_PORTS');
  // Tắt rule nền tảng, tạo 3 rule theo thứ tự
  await lib.setDisabled(page, h, 'lan', /Rule nen tang/, true);
  await lib.addRule(page, h, { iface: 'lan', type: 'block', proto: 'icmp', srctype: 'lan', dsttype: 'any', log: true,
    descr: 'TH1 - Block ICMP LAN net -> Any', shot: 'TH1b_Rule_Block_ICMP_Form' });
  await lib.addRule(page, h, { iface: 'lan', type: 'pass', proto: 'tcp/udp', srctype: 'lan', dsttype: 'any', port: '53',
    descr: 'TH1 - Pass DNS TCP/UDP 53' });
  await lib.addRule(page, h, { iface: 'lan', type: 'pass', proto: 'tcp', srctype: 'lan', dsttype: 'any', port: 'WEB_PORTS',
    descr: 'TH1 - Pass HTTP/HTTPS TCP 80/443' });
  await lib.applyRules(page, h, 'lan');
  await h.shot(page, 'TH1c_LAN_Rules');
  await lib.resetStates(page, h);
};
