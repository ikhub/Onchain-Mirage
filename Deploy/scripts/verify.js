const hre = require("hardhat");
require("dotenv").config();

async function verifyContract(address, type) {
  let args = [];

  if (type === "metadata") {
    const initialOwner = process.env.METADATA_INITIAL_OWNER;
    if (!initialOwner) throw new Error("Missing METADATA_INITIAL_OWNER in .env");
    args = [initialOwner];
  }

  if (type === "nft") {
    const metadataAddress = process.env.METADATA_CONTRACT_ADDRESS;
    const royaltyReceiver = process.env.ROYALTY_RECEIVER;
    const royaltyFeeNumerator = process.env.ROYALTY_FEE_BPS;
    const initialOwner = process.env.NFT_INITIAL_OWNER;
    const maxPerWallet = process.env.MAX_PER_WALLET;

    if (!metadataAddress || !royaltyReceiver || !royaltyFeeNumerator || !initialOwner || !maxPerWallet) {
      throw new Error("Missing one or more NFT constructor args in .env");
    }

    args = [metadataAddress, royaltyReceiver, royaltyFeeNumerator, initialOwner, maxPerWallet];
  }

  console.log(`Verifying ${type} contract at ${address} with args:`, args);

  try {
    await hre.run("verify:verify", {
      address,
      constructorArguments: args,
    });
    console.log(`${type} verification requested.`);
  } catch (e) {
    console.error(`${type} verification failed:`, e.message || e);
  }
}

async function main() {
  const metadataAddress = process.env.METADATA_CONTRACT_ADDRESS;
  const nftAddress = process.env.NFT_CONTRACT_ADDRESS;

  if (!metadataAddress && !nftAddress) {
    console.error("Set METADATA_CONTRACT_ADDRESS or NFT_CONTRACT_ADDRESS in .env");
    process.exit(1);
  }

  if (metadataAddress) {
    await verifyContract(metadataAddress, "metadata");
  }

  if (nftAddress) {
    await verifyContract(nftAddress, "nft");
  }
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
