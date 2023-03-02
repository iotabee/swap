require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  defaultNetwork: "smrevm1070",
  networks:{
    smrevm1070:{
      url:"https://json-rpc.evm.testnet.shimmer.network/",
      accounts:[process.env.RMS_CONTRACT_PRIVATEKEY],
    }
  }
};
