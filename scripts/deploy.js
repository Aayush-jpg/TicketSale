require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const Web3 = require('web3');
const { interface, bytecode } = require('../scripts/compile');

// Debug: Print environment variables (remove these in production)
console.log("Loaded Mnemonic: ", process.env.MNEMONIC); 
console.log('INFURA_URL exists:', !!process.env.INFURA_URL);

if (!process.env.MNEMONIC || !process.env.INFURA_URL) {
  throw new Error('Please check that your .env file exists and has MNEMONIC and INFURA_URL');
}

// Create provider with explicit values
const provider = new HDWalletProvider(
  process.env.MNEMONIC,
  process.env.INFURA_URL
);

const web3 = new Web3(provider);


const deploy = async () => {
  try {
    const accounts = await web3.eth.getAccounts();
    console.log('Attempting to deploy from account', accounts[0]);

    const result = await new web3.eth.Contract(JSON.parse(interface))
      .deploy({ 
        data: bytecode, 
        arguments: [100, web3.utils.toWei('0.01', 'ether')] // Adjust constructor arguments if necessary
      })
      .send({ 
        from: accounts[0], 
        gas: '3000000' // Gas limit
      });

    console.log('Contract deployed to', result.options.address);
  } catch (error) {
    console.error('Error during deployment:', error);
  } finally {
    provider.engine.stop(); // Stops the provider engine after deployment
  }
};

deploy();
