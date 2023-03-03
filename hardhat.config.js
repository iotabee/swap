require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings:{
      optimizer:{
        enabled:true,
        runs:200
      }
    }
  },
  defaultNetwork: "smrevm1070",
  networks:{
    smrevm1070:{
      url:"https://json-rpc.evm.testnet.shimmer.network",
      accounts:[process.env.RMS_CONTRACT_PRIVATEKEY],
    },
    mumbai:{
      url:"https://rpc-mumbai.maticvigil.com",
      accounts:[process.env.RMS_CONTRACT_PRIVATEKEY]
    }
  }
};