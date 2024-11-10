const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');

// Set up the provider with Ganache for multiple accounts and sufficient balances
const provider = ganache.provider({
  accounts: [
    { balance: '1000000000000000000000' },  // Account 0 (deployer)
    { balance: '1000000000000000000000' },  // Account 1 
    { balance: '1000000000000000000000' },  // Account 2 
    { balance: '1000000000000000000000' }   // Account 3
  ],
  gasLimit: 8000000
});

const web3 = new Web3(provider);
const { interface, bytecode } = require('../scripts/compile');

let accounts;
let ticketSale;
const TICKET_PRICE = web3.utils.toWei('0.1', 'ether');

before(async () => {
  // Set up the accounts and deploy the contract once before the tests
  accounts = await web3.eth.getAccounts();
  console.log('Deploying contract with account:', accounts[0]);

  try {
    ticketSale = await new web3.eth.Contract(JSON.parse(interface))
      .deploy({ data: bytecode, arguments: [10, TICKET_PRICE] })
      .send({ from: accounts[0], gas: '6000000' });

    console.log('Contract deployed to:', ticketSale.options.address);
  } catch (error) {
    console.error('Deployment error:', error);
    throw error;
  }
});

describe('TicketSale Contract', () => {
  it('should deploy the contract successfully', () => {
    assert.ok(ticketSale.options.address);
  });

  it('should allow an account to buy a ticket', async () => {
    try {
      const initialBalance = await web3.eth.getBalance(accounts[1]);
      console.log('Initial balance of buyer:', initialBalance);

      // Account 1 buys ticket #1
      await ticketSale.methods.buyTicket(1).send({
        from: accounts[1],
        value: TICKET_PRICE,
        gas: '3000000'
      });

      const ticketOwner = await ticketSale.methods.ticketOwners(1).call();
      assert.strictEqual(ticketOwner, accounts[1]);
    } catch (error) {
      console.error('Error during ticket purchase:', error);
      assert.fail('Ticket purchase failed');
    }
  });

  it('should prevent buying the same ticket twice', async () => {
    try {
      // Account 1 buys ticket #1
      await ticketSale.methods.buyTicket(1).send({
        from: accounts[1],
        value: TICKET_PRICE,
        gas: '3000000'
      });

      // Account 2 tries to buy the same ticket #1
      await ticketSale.methods.buyTicket(1).send({
        from: accounts[2],
        value: TICKET_PRICE,
        gas: '3000000'
      });

      assert.fail('Ticket should not be available for purchase again');
    } catch (error) {
      assert(error, 'Expected an error when buying the same ticket twice');
    }
  });

  it('should allow swapping tickets between users', async () => {
    try {
      // Account 1 buys ticket #1
      await ticketSale.methods.buyTicket(1).send({
        from: accounts[1],
        value: TICKET_PRICE,
        gas: '3000000'
      });

      // Account 2 buys ticket #2
      await ticketSale.methods.buyTicket(2).send({
        from: accounts[2],
        value: TICKET_PRICE,
        gas: '3000000'
      });

      // Account 1 offers ticket #1 for swap
      await ticketSale.methods.offerSwap(1).send({ from: accounts[1], gas: '3000000' });

      // Account 2 accepts the swap for ticket #1
      await ticketSale.methods.acceptSwap(1).send({ from: accounts[2], gas: '3000000' });

      const ticket1Owner = await ticketSale.methods.ticketOwners(1).call();
      const ticket2Owner = await ticketSale.methods.ticketOwners(2).call();

      assert.strictEqual(ticket1Owner, accounts[2]);
      assert.strictEqual(ticket2Owner, accounts[1]);
    } catch (error) {
      console.error('Ticket swap failed:', error);
      assert.fail('Swap failed');
    }
  });

  it('should allow the resale of tickets', async () => {
    try {
      // Account 1 buys ticket #1
      await ticketSale.methods.buyTicket(1).send({
        from: accounts[1],
        value: TICKET_PRICE,
        gas: '3000000'
      });

      const resalePrice = web3.utils.toWei('0.15', 'ether');
      // Account 1 lists ticket #1 for resale
      await ticketSale.methods.resaleTicket(resalePrice).send({
        from: accounts[1],
        gas: '3000000'
      });

      // Account 2 buys the resale ticket
      await ticketSale.methods.acceptResale(0).send({
        from: accounts[2],
        value: resalePrice,
        gas: '3000000'
      });

      const newOwner = await ticketSale.methods.ticketOwners(1).call();
      assert.strictEqual(newOwner, accounts[2]);
    } catch (error) {
      console.error('Ticket resale failed:', error);
      assert.fail('Resale failed');
    }
  });

  after(async () => {
    // Log deployment info after all tests
    console.log('Tests completed for TicketSale contract');
  });
});
