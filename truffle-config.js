const path = require("path");

module.exports = {
    networks: {
      development: {
        host: "127.0.0.1", // Localhost (default: none)
        port: 7545,        // Ganache port
        network_id: "*",   // Any network (default: none)
      },
    },
    compilers: {
      solc: {
        version: "0.8.17", // Specify the Solidity version
      },
    },
  };
  
  
