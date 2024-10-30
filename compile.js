const fs = require('fs');
const path = require('path');
const solc = require('solc');

const filePath = path.resolve(__dirname, 'TicketSale.sol');
const source = fs.readFileSync(filePath, 'utf8');

const input = {
    language: 'Solidity',
    sources: {
        'TicketSale.sol': {
            content: source,
        },
    },
    settings: {
        outputSelection: {
            '*': {
                '*': ['*'],
            },
        },
    },
};

const output = JSON.parse(solc.compile(JSON.stringify(input)));

// Save ABI to a text file
fs.writeFileSync(path.resolve(__dirname, 'ABI.txt'), JSON.stringify(output.contracts['TicketSale.sol']['TicketSale'].abi, null, 2));

// Save Bytecode to a text file
fs.writeFileSync(path.resolve(__dirname, 'Bytecode.txt'), output.contracts['TicketSale.sol']['TicketSale'].evm.bytecode.object);

// Optionally print to console
console.log('ABI and Bytecode saved to ABI.txt and Bytecode.txt');
