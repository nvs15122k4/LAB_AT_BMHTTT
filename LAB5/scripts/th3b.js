const lib = require('./lib');
module.exports = async (page, h) => {
  await lib.addRule(page, h, { iface: 'opt1', type: 'block', proto: 'any', srctype: 'opt1', dsttype: 'lan', log: true, top: true,
    descr: 'TH3 - Block DMZ net -> LAN net', shot: 'TH3g_Rule_Block_DMZ_LAN_Form' });
  await lib.applyRules(page, h, 'opt1');
  await h.shot(page, 'TH3h_DMZ_Rules_Block_Tren_Pass');
  await lib.resetStates(page, h);
};
