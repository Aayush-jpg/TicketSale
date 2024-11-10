const path = require('path');
const fs = require('fs');
const solc = require('solc');

// Path to the contract
const contractPath = path.resolve(__dirname, '../TicketSale.sol');

// Read the source code of the contract
const sourceCode = fs.readFileSync(contractPath, 'utf8');

// Define input for the Solidity compiler
const input = {
  language: 'Solidity',
  sources: {
    'TicketSale.sol': {
      content: sourceCode,
    },
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['*'],
      },
    },
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};

// Compile the contract using solc
const output = JSON.parse(solc.compile(JSON.stringify(input)));

// Log the entire output to debug and check the contract compilation
console.log("Compilation Output:", output);

// Check for errors in the compilation
if (output.errors) {
  output.errors.forEach((error) => {
    if (error.severity === 'error') {
      throw new Error(`Compilation Error: ${error.message}`);
    }
    console.warn(`Warning: ${error.message}`);
  });
}

// Try to get the contract from the output
const contract = output.contracts['TicketSale.sol'] ? output.contracts['TicketSale.sol']['TicketSale'] : undefined;

// If contract is not found in the output, throw an error
if (!contract) {
  throw new Error('Contract not found in compilation output');
}

// Export ABI and bytecode for deployment
module.exports = {
  interface: JSON.stringify(contract.abi),
  bytecode: contract.evm.bytecode.object,
};

// Log a success message when compilation is complete
console.log('Contract compiled successfully!');
