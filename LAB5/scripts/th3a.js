const lib = require('./lib');
module.exports = async (page, h) => {
  await lib.setDisabled(page, h, 'lan', /^TH2 -/, true);
  await lib.setDisabled(page, h, 'lan', /Rule nen tang/, false);
  await lib.applyRules(page, h, 'lan');
  await h.shot(page, 'TH3a_LAN_Rules_Truoc_TH3');
  await page.goto(h.BASE + '/firewall_rules.php?if=opt1');
  await h.shot(page, 'TH3b_DMZ_Rules_Empty');
  await lib.addRule(page, h, { iface: 'opt1', type: 'pass', proto: 'any', srctype: 'opt1', dsttype: 'any',
    descr: 'TH3 - Pass DMZ net -> Any', shot: 'TH3c_Rule_Pass_DMZ_Form' });
  await lib.applyRules(page, h, 'opt1');
  await h.shot(page, 'TH3d_DMZ_Rules_Baseline');
  await lib.resetStates(page, h);
};
