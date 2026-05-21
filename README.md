Onchain Mirage is a fully onchain animated NFT artwork deployed on Base Network.

When we say 'onchain' we really mean it in it's literal sense. From the layers, the mixing, the rarity, the generative description, the generated image, metadata, etc. all are onchain and not stored in any centralized or decentralized server. The only single point of failure is the blockchain itself. If Base Network cease to exist. the nfts will be lost forever. This is similar to everyone will lose their Bitcoins if the Bitcoin blockchain does not exist anymore.

This repository contains all the files used for the "Onchain Mirage" NFT collection which anyone can use to cross check the codes we used or anyone can use this as a blueprint for similar collection. Although nothing in this repository has copyright except from the dependencies used, Use this as a test or to learn and deploy in testnets. 
Using the everything verbatim and deploying on any blockchain would be unfair and may be flagged as counterfeit and use it at your own risk. You are free to use the artwork layers for your projects without duplicating everything ditto.

We have Four folders here:
A. Layers
This contains all the svg layers used to generate the nfts. This folder contains the layers (each layer is a Property/trait in metadata and the inside files are Attributes/Variations).
	i. Field (This is basically the background covering the full canvas)
	ii. Paradigm (This is a decorative design on top of the Field with transparent background covering the full canvas)
	iii. Energy (This is like a glow on top of Paradigm designs in the centre of the canvas again with transparent background)
	iv. Motif (This is the central object obviously with transparent background)
	v. Merkle Wheel (This is a design of a wheel with eight spikes with transparent background)
B. SampleOutputs
This is the output which happens when the contract mints a nft. Have provided some sample images and the metadata json.
The generated images and the metadata json are not stored anywhere unlike traditional nfts, the smart contracts are programmed to generate them on each mint and store them as part of the NFT itself. The minter address and the timestamp of the block serves as different seeds.

C. Deploy
This folder contains the Hardhat bundle used to deploy the contracts. Due to limitations in solidity and the blockchain itself as well as to keep things simpler, we have used two contracts, viz, OnchainMirageMetadata (which serves as the image and metadata of the NFTs) and OnchainMirage (which is the main nft contract).
First we deployed OnchainMirageMetadata and then we populated it with the tables (again we didn't hardcode them because of limit constraints).
Then we deployed OnchainMirage and gave it the 'minter' privilege in OnchainMirageMetadata (without this the nftcontract would mint 'blank' nfts without any image or metadata).
After granting the minter role we renounced ownership of the OnchainMirageMetadata contract (So that we cannot add or alter anything afterwards).
Could have deployed the two contracts using remix and used the contract functions to populate the metadata tables, but that would have been a tedious job with chance of mistake, so used the deploy_metadata script.
If you are using this contract as a blueprint, note that this contract does not have a price per nft or batch mint enabled. Have used a donation style mint system where anyone can mint a NFT by any amount greater than zero they wish. 

Deployment steps (Assuming you have cloned and downloaded this repo)

1. Go to the Deploy folder
 cd deploy

2. Create .env
   cp .env.example .env
   Fill in values:
     # RPC endpoints
     BASE_SEPOLIA_RPC=     
     BASE_MAINNET_RPC=

     # Wallet private key (do NOT commit real private keys)
     DEPLOYER_PRIVATE_KEY=
     
     # Etherscan / explorer API key
     ETHERSCAN_API_KEY=
     
     # MetadataGenerator contract args
     METADATA_INITIAL_OWNER=0x (This is usually your public address)
     
     # NFT contract deployment args
     Make sure the METADATA_CONTRACT_ADDRESS is filled.
     ROYALTY_RECEIVER= (Address to receive Royalty on aftersales)
     ROYALTY_FEE_BPS=500 (500 means 5 percent, adjust according to your needs)
     NFT_INITIAL_OWNER=0x (This is usually your public address)
     MAX_PER_WALLET=25 (adjust according to your need)
     
     # Grant minter     
     MINTER_ADDRESS= (The NFT Contract Address) | Without minter role the nft contract will mint 'blank' NFTs.
     # Metadata JSON source directory
     METADATA_SOURCE_DIR=./source/OnChainMirage_Tables

     # Deployed Contract Addresses
     NFT_CONTRACT_ADDRESS=0x (Add this after deployment of the nftcontract)
     METADATA_CONTRACT_ADDRESS=0x (Fill this after the MetadataGenerator contract is deploed)


     
3. Install dependencies
   npm install

4. Compile
   npx hardhat compile

5. Deploy metadata contract
   npx hardhat run scripts/deploy_metadata.js --network baseSepolia
   npx hardhat run scripts/deploy_metadata.js --network baseMainnet
   Copy address -> set METADATA_CONTRACT_ADDRESS in .env

6. Upload metadata JSONs
   npx hardhat run scripts/upload_metadata.js --network baseSepolia
   npx hardhat run scripts/upload_metadata.js --network baseMainnet

7. Deploy NFT contract
   npx hardhat run scripts/deploy_nft.js --network baseSepolia
   npx hardhat run scripts/deploy_nft.js --network baseMainnet
   Copy address -> set NFT_CONTRACT_ADDRESS in .env

8. Grant minter role
   npx hardhat run scripts/grantMetadataMinter.js --network baseSepolia
   npx hardhat run scripts/grantMetadataMinter.js --network baseMainnet

9. Verify contracts
   For metadata:
     CONTRACT_ADDRESS=0x... CONTRACT_TYPE=metadata in .env
   For NFT:
     CONTRACT_ADDRESS=0x... CONTRACT_TYPE=nft in .env
   Run:
     npx hardhat run scripts/verify.js --network baseSepolia
     npx hardhat run scripts/verify.js --network baseMainnet

10. For Contracts Partially verified use --force
    npx hardhat run scripts/force_verify.js --network baseSepolia
    npx hardhat run scripts/force_verify.js --network baseMainnet

Notes
- Constructor args automatically read from .env
- Metadata constructor: [METADATA_INITIAL_OWNER]
- NFT constructor: [METADATA_CONTRACT_ADDRESS, ROYALTY_RECEIVER, ROYALTY_FEE_BPS, NFT_INITIAL_OWNER, MAX_PER_WALLET]
- grantMinter resolves MINTER_ROLE directly from contract
- viaIR enabled for solidity optimizer

