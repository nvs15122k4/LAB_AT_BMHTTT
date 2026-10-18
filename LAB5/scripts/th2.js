const lib = require('./lib');
module.exports = async (page, h) => {
  await lib.setDisabled(page, h, 'lan', /^TH1 -/, true);
  await lib.setDisabled(page, h, 'lan', /Rule nen tang/, true);
  await lib.addRule(page, h, { iface: 'lan', type: 'pass', proto: 'any', srctype: 'single', src: '10.0.0.2', dsttype: 'any',
    descr: 'TH2 - Pass DC 10.0.0.2 -> Any', shot: 'TH2a_Rule_Pass_DC_Form' });
  await lib.addRule(page, h, { iface: 'lan', type: 'block', proto: 'any', srctype: 'lan', dsttype: 'any', log: true,
    descr: 'TH2 - Block LAN net -> Any' });
  await lib.applyRules(page, h, 'lan');
  await h.shot(page, 'TH2b_LAN_Rules');
  await lib.resetStates(page, h);
};
