const hre = require("hardhat");
require("dotenv").config();

async function main() {
  await hre.run("compile");

  const metadataAddress = process.env.METADATA_CONTRACT_ADDRESS;
  const royaltyReceiver = process.env.ROYALTY_RECEIVER;
  const royaltyFeeNumerator = process.env.ROYALTY_FEE_BPS;
  const initialOwner = process.env.NFT_INITIAL_OWNER;
  const maxPerWallet = process.env.MAX_PER_WALLET;

  if (!metadataAddress || !royaltyReceiver || !royaltyFeeNumerator || !initialOwner || !maxPerWallet) {
    console.error("Missing one or more constructor args. Check .env");
    process.exit(1);
  }

  const Contract = await hre.ethers.getContractFactory("OnchainMirage");
  const args = [
    metadataAddress,
    royaltyReceiver,
    royaltyFeeNumerator,
    initialOwner,
    maxPerWallet,
  ];

  const contract = await Contract.deploy(...args);
  await contract.waitForDeployment();

  console.log("OnchainMirage deployed to:", contract.target);
  console.log("Constructor args:", args);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
