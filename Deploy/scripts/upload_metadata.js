const hre = require("hardhat");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

async function main() {
  const metadataAddress = process.env.METADATA_CONTRACT_ADDRESS;
  if (!metadataAddress) {
    console.error("Set METADATA_CONTRACT_ADDRESS in .env");
    process.exit(1);
  }

  const dir = process.env.METADATA_SOURCE_DIR || "./source/OnChainMirage_Tables";
  const files = fs.readdirSync(dir).filter(f => f.endsWith("_table.json")).sort();

  if (files.length === 0) {
    console.error("No *_table.json files found in", dir);
    process.exit(1);
  }

  const contract = await hre.ethers.getContractAt("OnchainMirageMetadata", metadataAddress);

  for (const file of files) {
    const content = JSON.parse(fs.readFileSync(path.join(dir, file), "utf8"));
    const { names, svgs, weights, phrases } = content;

    let tx;
    if (file.includes("field")) {
      tx = await contract.setFields(names, svgs, weights, phrases);
      console.log("Uploading fields from", file);
    } else if (file.includes("paradigm")) {
      tx = await contract.setParadigms(names, svgs, weights, phrases);
      console.log("Uploading paradigms from", file);
    } else if (file.includes("energy")) {
      tx = await contract.setEnergies(names, svgs, weights, phrases);
      console.log("Uploading energies from", file);
    } else if (file.includes("motif")) {
      tx = await contract.setMotifs(names, svgs, weights, phrases);
      console.log("Uploading motifs from", file);
    } else if (file.includes("merklewheel")) {
      tx = await contract.setMerkleWheels(names, svgs, weights, phrases);
      console.log("Uploading merklewheels from", file);
    } else {
      console.error("Unknown table type:", file);
      continue;
    }

    console.log("Tx sent:", tx.hash);
    await tx.wait();
    console.log(file, "uploaded");
  }

  console.log("All metadata uploaded.");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
