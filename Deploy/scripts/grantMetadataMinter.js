const hre = require("hardhat");
require("dotenv").config();

async function main() {
  const metadataAddress = process.env.METADATA_CONTRACT_ADDRESS;
  const nftAddress = process.env.NFT_CONTRACT_ADDRESS;

  if (!metadataAddress || !nftAddress) {
    console.error("Set METADATA_CONTRACT_ADDRESS and NFT_CONTRACT_ADDRESS in .env");
    process.exit(1);
  }

  const metadata = await hre.ethers.getContractAt("OnchainMirageMetadata", metadataAddress);

  try {
    const role = await metadata.MINTER_ROLE();
    console.log("Resolved MINTER_ROLE:", role);

    const tx = await metadata.grantRole(role, nftAddress);
    console.log("grantRole tx sent:", tx.hash);
    await tx.wait();

    console.log("NFT contract", nftAddress, "granted MINTER_ROLE on metadata contract", metadataAddress);
  } catch (e) {
    console.error("Failed to grant minter role:", e);
  }
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
