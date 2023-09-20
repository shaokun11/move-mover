require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.6.6",
  settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
};
