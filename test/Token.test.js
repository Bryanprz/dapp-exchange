import { tokens, EVM_MESSAGE } from './helpers';

// require the ABIs representation of the contract under test
const Token = artifacts.require('./Token');

require('chai')
  .use(require('chai-as-promised'))
  .should();

// 2nd arg is callback that takes all accounts
// from our personal blockchain
//
// all tests should be written inside this contract
// func
contract('Token', ([deployer, recipient, exchange]) => {
  const name = 'DApp Token';
  const symbol = 'DAPP';
  const totalSupply = tokens(1000000).toString();
  const decimals = '18';
  let token;

  beforeEach(async () => {
    // 1. fetch token from blockchain
    token = await Token.new();
  })

  describe('deployment', () => {
    it('tracks the name', async () => {

      // 2. Read token name here...
      // (any calls to any contracts MUST use await)
      const result = await token.name();

      result.should.equal(name)
    });

    it('tracks the symbol', async () => {
      const result = await token.symbol();
      result.should.equal(symbol);
    });

    it('tracks the decimals', async () => {
      const result = await token.decimals();
      result.toString().should.equal(decimals);
    });

    it('tracks the total supply', async () => {
      // Check totalsupply as string b/c actual
      // number is too large for JS to handle
      const result = await token.totalSupply();

      // always compare strings to strings (same type) 
      // when using chai
      result.toString().should.equal(totalSupply.toString());
    });

    it('assigns the total supply to the deployer', async () => {
      const result = await token.balanceOf(deployer);

      // always compare strings to strings (same type) 
      // when using chai
      result.toString().should.equal(totalSupply.toString());
    });
  })

  describe('sending tokens', () => {
    let amount;
    let result;

    describe('success', async () => {
      beforeEach(async () => {
        // transfer
        // 3rd arg in transfer() is metadata for transfer
        amount = tokens(100);
        result = await token.transfer(recipient, amount, { from: deployer });
      })

      it('transfers token balances', async () => {
        let balanceOf;
        balanceOf = await token.balanceOf(deployer);
        balanceOf.toString().should.equal(tokens(999900).toString());

        balanceOf = await token.balanceOf(recipient);
        balanceOf.toString().should.equal(tokens(100).toString());
      })

      it('emits a Transfer event', async () => {
        //console.log(result.logs);
        const log = result.logs[0];
        log.event.should.equal('Transfer');
        const event = log.args;
        event.from.toString().should.equal(deployer, 'from is correct');
        event.to.toString().should.equal(recipient, 'to is correct');
        event.value.toString().should.equal(amount.toString(), 'value is correct')
      })
    })

    describe('failure', async () => {
      it('rejects insufficient balances', async () => {
        let invalidAmount;
        invalidAmount = tokens(100000000); // 100 million is greater than total supply; invalid
        await token.transfer(recipient, invalidAmount, { from: deployer }).should.be.rejectedWith(EVM_MESSAGE);

        // Attempt transfer of tokens, when you have none
        invalidAmount = tokens(10); // recipient has none
        console.log(recipient);
        await token.transfer(deployer, invalidAmount, { from: recipient }).should.be.rejectedWith(EVM_MESSAGE);
      });

      it('rejects invalid recipients', async () => {
        // address 0x0 is invalid. Address 0 expressed in hexadecimal
        await token.transfer(0x0, amount, { from: deployer }).should.be.rejected;
      });
    })
  })

  describe('approving tokens', () => {
    let result;
    let amount;

    beforeEach(async () => {
      amount = tokens(100);
      // approve allowance on this exchange for the given amount
      result = await token.approve(exchange, amount, { from: deployer });
    })

    describe('success', () => {
      it('allocates an allowance for delegated token spending on an exchange', async () => {
        // token.allowance(deployer, exchange) says
        // for the deployer, what is the allowance I've provisioned on this exchange? 
        const allowance = await token.allowance(deployer, exchange);
        allowance.toString().should.equal(amount.toString());
      })

      it('emits an Approval event', async () => {
        const log = result.logs[0];
        log.event.should.equal('Approval');
        const event = log.args;
        event.owner.toString().should.equal(deployer, 'owner is correct');
        event.spender.toString().should.equal(exchange, 'spender is correct');
        event.value.toString().should.equal(amount.toString(), 'amount is correct')
      });
      
    })

    describe('failure', () => {
      it('rejects invalid spenders', async () => {
        await token.approve(0x0, amount, { from: deployer }).should.be.rejected;
      });
      
    })
  })

  describe('delegated token transfers', () => {
    let amount;
    let result;

    beforeEach(async () => {
      amount = tokens(100);
      await token.approve(exchange, amount, { from: deployer });
    })

    describe('success', async () => {
      beforeEach(async () => {
        result = await token.transferFrom(deployer, recipient, amount, { from: exchange });
      })

      it('transfers token balances', async () => {
        let balanceOf;
        balanceOf = await token.balanceOf(deployer);
        balanceOf.toString().should.equal(tokens(999900).toString());

        balanceOf = await token.balanceOf(recipient);
        balanceOf.toString().should.equal(tokens(100).toString());
      })

      it('resets the allowance', async () => {
        // token.allowance(deployer, exchange) says
        // for the deployer, what is the allowance I've provisioned on this exchange? 
        const allowance = await token.allowance(deployer, exchange);
        allowance.toString().should.equal('0');
      })

      it('emits a Transfer event', async () => {
        console.log(result.logs);
        const log = result.logs[0];
        log.event.should.equal('Transfer');
        const event = log.args;
        event.from.toString().should.equal(deployer, 'from is correct');
        event.to.toString().should.equal(recipient, 'to is correct');
        event.value.toString().should.equal(amount.toString(), 'value is correct')
      })
    })

    describe('failure', async () => {
      it('rejects insufficient amounts', async () => {
        // Attempt to transfer too many tokens
        const invalidAmount = tokens(10000000);
        await token.transferFrom(deployer, recipient, invalidAmount, { from: exchange })
          .should.be.rejectedWith(EVM_MESSAGE);
      });

      it('rejects invalid recipients', async () => {
        // address 0x0 is invalid. Address 0 expressed in hexadecimal
        await token.transferFrom(0x0, amount, { from: exchange }).should.be.rejected;
      });
    })
  })
})
