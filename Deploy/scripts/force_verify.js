require("dotenv").config();
const hre = require("hardhat");

async function main() {
  console.log("\n=== Onchain Mirage Force Verification ===\n");

  const network = hre.network.name;

  // --- Pull from .env (kept consistent with all other scripts) ---
  const metadataAddress = process.env.METADATA_CONTRACT_ADDRESS;
  const nftAddress = process.env.NFT_CONTRACT_ADDRESS;

  const metadataInitialOwner = process.env.METADATA_INITIAL_OWNER;
  const royaltyReceiver = process.env.ROYALTY_RECEIVER;
  const royaltyFeeBps = Number(process.env.ROYALTY_FEE_BPS) || 500;
  const nftInitialOwner = process.env.NFT_INITIAL_OWNER;
  const maxPerWallet = Number(process.env.MAX_PER_WALLET) || 25;

  if (!metadataAddress || !nftAddress) {
    throw new Error("Missing contract addresses in .env");
  }

  console.log(`Verifying on network: ${network}`);

  // --- Constructor arguments ---
  const metadataArgs = [metadataInitialOwner];
  const nftArgs = [
    metadataAddress,
    royaltyReceiver,
    royaltyFeeBps,
    nftInitialOwner,
    maxPerWallet,
  ];

  // --- Metadata contract ---
  console.log("\nVerifying OnchainMirageMetadata...");
  try {
    await hre.run("verify:verify", {
      address: metadataAddress,
      constructorArguments: metadataArgs,
      force: true,
    });
    console.log("✓ Metadata contract verified successfully.");
  } catch (err) {
    console.error("Metadata verification failed:", err.message);
  }

  // --- NFT contract ---
  console.log("\nVerifying OnchainMirage...");
  try {
    await hre.run("verify:verify", {
      address: nftAddress,
      constructorArguments: nftArgs,
      force: true,
    });
    console.log("✓ NFT contract verified successfully.");
  } catch (err) {
    console.error("NFT verification failed:", err.message);
  }

  console.log("\nForce verification process complete.\n");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
