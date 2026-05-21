require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

const {
  BASE_SEPOLIA_RPC,
  BASE_MAINNET_RPC,
  DEPLOYER_PRIVATE_KEY,
  ETHERSCAN_API_KEY
} = process.env;

module.exports = {
  solidity: {
    version: "0.8.30",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      viaIR: true
    }
  },
  networks: {
    baseSepolia: {
      url: BASE_SEPOLIA_RPC || "https://sepolia.base.org",
      chainId: 84532,
      accounts: DEPLOYER_PRIVATE_KEY ? [DEPLOYER_PRIVATE_KEY] : []
    },
    baseMainnet: {
      url: BASE_MAINNET_RPC || "https://mainnet.base.org",
      chainId: 8453,
      accounts: DEPLOYER_PRIVATE_KEY ? [DEPLOYER_PRIVATE_KEY] : []
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY || ""
  },
  paths: {
    sources: "./source",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
