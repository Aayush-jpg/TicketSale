require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const Web3 = require('web3');
const { abi, evm } = require('../build/contracts/TicketSale.json'); // Adjust path as necessary

// Ensure environment variables are set
if (!process.env.MNEMONIC || !process.env.GANACHE_URL) {
  throw new Error('Please check that your .env file exists and has MNEMONIC and GANACHE_URL');
}

// Create provider with explicit values
const provider = new HDWalletProvider(
  process.env.MNEMONIC,
  process.env.GANACHE_URL
);

const web3 = new Web3(provider);

const deploy = async () => {
  try {
    const accounts = await web3.eth.getAccounts();
    console.log('Attempting to deploy from account', accounts[0]);

    const result = await new web3.eth.Contract(abi)
      .deploy({ 
        data: evm.bytecode.object, 
        arguments: [100, web3.utils.toWei('0.01', 'ether')] // Adjust constructor arguments as needed
      })
      .send({ 
        from: accounts[0], 
        gas: '3000000' 
      });

    console.log('Contract deployed to', result.options.address);
  } catch (error) {
    console.error('Error during deployment:', error);
  } finally {
    provider.engine.stop();
  }
};

deploy();
