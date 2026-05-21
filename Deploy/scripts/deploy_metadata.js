const hre = require("hardhat");
require("dotenv").config();

async function main() {
  await hre.run("compile");

  const initialOwner = process.env.METADATA_INITIAL_OWNER;
  if (!initialOwner) {
    console.error("Set METADATA_INITIAL_OWNER in .env");
    process.exit(1);
  }

  const Contract = await hre.ethers.getContractFactory("OnchainMirageMetadata");
  const contract = await Contract.deploy(initialOwner);
  await contract.waitForDeployment();

  console.log("OnchainMirageMetadata deployed to:", contract.target);
  console.log("Constructor args:", [initialOwner]);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
