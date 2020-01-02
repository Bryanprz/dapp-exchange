export const ETHER_ADDRESS = '0x0000000000000000000000000000000000000000';

export const EVM_MESSAGE = 'VM Exception while processing transaction: revert';

export const ether = (n) => {
  // utility fnc to convert number to Big Number
  return new web3.utils.BN(
    // tokens under test here are not explicitly ether
    // but this utility fnc works the same bc of the 18
    // decimal places in both ether and our created token
    web3.utils.toWei(n.toString(), 'ether')
  )
};

export const tokens = (n) => ether(n);
