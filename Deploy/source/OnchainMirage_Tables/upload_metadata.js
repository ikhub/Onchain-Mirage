const hre = require("hardhat");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

const progressFile = path.join(__dirname, "upload_progress.json");

function loadProgress() {
  if (fs.existsSync(progressFile)) {
    return JSON.parse(fs.readFileSync(progressFile, "utf8"));
  }
  return {};
}

function saveProgress(progress) {
  fs.writeFileSync(progressFile, JSON.stringify(progress, null, 2));
}

async function uploadWithResume(setFunc, appendFunc, chunks, category, retries = 3) {
  let progress = loadProgress();
  let startIndex = progress[category] || 0;

  for (let i = startIndex; i < chunks.length; i++) {
    let attempt = 0;
    let success = false;

    while (attempt < retries && !success) {
      try {
        let tx;
        if (i === 0) {
          tx = await setFunc(
            chunks[i].names,
            chunks[i].svgs,
            chunks[i].weights,
            chunks[i].phrases
          );
        } else {
          tx = await appendFunc(
            chunks[i].names,
            chunks[i].svgs,
            chunks[i].weights,
            chunks[i].phrases
          );
        }
        const receipt = await tx.wait();
        console.log(
          `${category} chunk ${i + 1}/${chunks.length} uploaded: ${chunks[i].names.length} items, Gas used: ${receipt.gasUsed.toString()}`
        );

        success = true;
        progress[category] = i + 1;
        saveProgress(progress);
      } catch (err) {
        attempt++;
        console.warn(`${category} chunk ${i + 1} attempt ${attempt} failed: ${err.message}`);

        if (attempt < retries) {
          console.log(`Retrying ${category} chunk ${i + 1}...`);

          if (err.message.toLowerCase().includes("out of gas") && chunks[i].names.length > 1) {
            const mid = Math.floor(chunks[i].names.length / 2);
            const firstHalf = {
              names: chunks[i].names.slice(0, mid),
              svgs: chunks[i].svgs.slice(0, mid),
              weights: chunks[i].weights.slice(0, mid),
              phrases: chunks[i].phrases.slice(0, mid),
            };
            const secondHalf = {
              names: chunks[i].names.slice(mid),
              svgs: chunks[i].svgs.slice(mid),
              weights: chunks[i].weights.slice(mid),
              phrases: chunks[i].phrases.slice(mid),
            };
            chunks.splice(i, 1, firstHalf, secondHalf);
            console.log(`${category} chunk split into two smaller chunks due to gas limit.`);
          }
        }
      }
    }
  }
}

async function main() {
  const metadataAddr = process.env.METADATA_CONTRACT_ADDRESS;
  if (!metadataAddr) {
    throw new Error("Missing METADATA_CONTRACT_ADDRESS in .env");
  }

  const metadata = await hre.ethers.getContractAt(
    "OnchainMirageMetadata",
    metadataAddr
  );

  const categories = [
    { name: "energies", file: "energy_table.json", set: metadata.setEnergies, append: metadata.appendEnergies },
    { name: "fields", file: "field_table.json", set: metadata.setFields, append: metadata.appendFields },
    { name: "merklewheels", file: "merklewheel_table.json", set: metadata.setMerkleWheels, append: metadata.appendMerkleWheels },
    { name: "motifs", file: "motif_table.json", set: metadata.setMotifs, append: metadata.appendMotifs },
    { name: "paradigms", file: "paradigm_table.json", set: metadata.setParadigms, append: metadata.appendParadigms }
  ];

  for (const { name, file, set, append } of categories) {
    const filePath = path.join(__dirname, file);
    if (!fs.existsSync(filePath)) {
      console.warn(`⚠️ Skipping ${name} — file not found: ${file}`);
      continue;
    }
    const data = JSON.parse(fs.readFileSync(filePath, "utf8"));
    const chunks = Array.isArray(data) ? data : [data];

    console.log(`\nUploading ${name} (${chunks.length} chunks)...`);
    await uploadWithResume(set.bind(metadata), append.bind(metadata), chunks, name);
  }

  console.log("\n✅ All metadata uploaded successfully");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
