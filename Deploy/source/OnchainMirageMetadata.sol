// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IOnchainMirageMetadata {
    function setSeed(uint256 tokenId, uint256 seed) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract OnchainMirageMetadata is Ownable, AccessControl, IOnchainMirageMetadata {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // --- Traits ---
    string[] public fieldNames;
    string[] public fieldSvgs;
    uint16[] public fieldWeights;
    string[] public fieldPhrases;

    string[] public paradigmNames;
    string[] public paradigmSvgs;
    uint16[] public paradigmWeights;
    string[] public paradigmPhrases;

    string[] public energyNames;
    string[] public energySvgs;
    uint16[] public energyWeights;
    string[] public energyPhrases;

    string[] public motifNames;
    string[] public motifSvgs;
    uint16[] public motifWeights;
    string[] public motifPhrases;

    string[] public merkleWheelNames;
    string[] public merkleWheelSvgs;
    uint16[] public merkleWheelWeights;
    string[] public merkleWheelPhrases;

    // Seeds
    mapping(uint256 => uint256) private _tokenSeed;
    mapping(uint256 => bool) private _hasSeed;

    // Events
    event FieldSet(uint256 count);
    event ParadigmSet(uint256 count);
    event EnergySet(uint256 count);
    event MotifSet(uint256 count);
    event MerkleWheelSet(uint256 count);
    event SeedSet(uint256 tokenId, uint256 seed);

    /**
     * @dev Constructor. Set initial owner and grant admin role to deployer.
     * @param initialOwner initial owner address
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        // grant deployer admin to allow role management if needed
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // --- setters for tables (owner) ---
    function setFields(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        fieldNames = _copyStrings(names);
        fieldSvgs = _copyStrings(svgs);
        fieldWeights = _copyU16(weights);
        fieldPhrases = _copyStrings(phrases);
        emit FieldSet(fieldNames.length);
    }

    function setParadigms(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        paradigmNames = _copyStrings(names);
        paradigmSvgs = _copyStrings(svgs);
        paradigmWeights = _copyU16(weights);
        paradigmPhrases = _copyStrings(phrases);
        emit ParadigmSet(paradigmNames.length);
    }

    function setEnergies(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        energyNames = _copyStrings(names);
        energySvgs = _copyStrings(svgs);
        energyWeights = _copyU16(weights);
        energyPhrases = _copyStrings(phrases);
        emit EnergySet(energyNames.length);
    }

    function setMotifs(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        motifNames = _copyStrings(names);
        motifSvgs = _copyStrings(svgs);
        motifWeights = _copyU16(weights);
        motifPhrases = _copyStrings(phrases);
        emit MotifSet(motifNames.length);
    }

    function setMerkleWheels(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        merkleWheelNames = _copyStrings(names);
        merkleWheelSvgs = _copyStrings(svgs);
        merkleWheelWeights = _copyU16(weights);
        merkleWheelPhrases = _copyStrings(phrases);
        emit MerkleWheelSet(merkleWheelNames.length);
    }

    // --- append helper functions ---
    function appendFields(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        _appendStringArray(fieldNames, names);
        _appendStringArray(fieldSvgs, svgs);
        _appendU16Array(fieldWeights, weights);
        _appendStringArray(fieldPhrases, phrases);
        emit FieldSet(fieldNames.length);
    }

    function appendParadigms(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        _appendStringArray(paradigmNames, names);
        _appendStringArray(paradigmSvgs, svgs);
        _appendU16Array(paradigmWeights, weights);
        _appendStringArray(paradigmPhrases, phrases);
        emit ParadigmSet(paradigmNames.length);
    }

    function appendEnergies(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        _appendStringArray(energyNames, names);
        _appendStringArray(energySvgs, svgs);
        _appendU16Array(energyWeights, weights);
        _appendStringArray(energyPhrases, phrases);
        emit EnergySet(energyNames.length);
    }

    function appendMotifs(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        _appendStringArray(motifNames, names);
        _appendStringArray(motifSvgs, svgs);
        _appendU16Array(motifWeights, weights);
        _appendStringArray(motifPhrases, phrases);
        emit MotifSet(motifNames.length);
    }

    function appendMerkleWheels(
        string[] calldata names,
        string[] calldata svgs,
        uint16[] calldata weights,
        string[] calldata phrases
    ) external onlyOwner {
        _appendStringArray(merkleWheelNames, names);
        _appendStringArray(merkleWheelSvgs, svgs);
        _appendU16Array(merkleWheelWeights, weights);
        _appendStringArray(merkleWheelPhrases, phrases);
        emit MerkleWheelSet(merkleWheelNames.length);
    }

    // --- seeds ---
    function setSeed(uint256 tokenId, uint256 seed) external override onlyRole(MINTER_ROLE) {
        require(!_hasSeed[tokenId], "Seed already set");
        _tokenSeed[tokenId] = seed;
        _hasSeed[tokenId] = true;
        emit SeedSet(tokenId, seed);
    }

    // --- internal helpers for copying/appending arrays ---
    function _copyStrings(string[] calldata src) internal pure returns (string[] memory) {
        string[] memory dst = new string[](src.length);
        for (uint256 i = 0; i < src.length; i++) {
            dst[i] = src[i];
        }
        return dst;
    }

    function _copyU16(uint16[] calldata src) internal pure returns (uint16[] memory) {
        uint16[] memory dst = new uint16[](src.length);
        for (uint256 i = 0; i < src.length; i++) {
            dst[i] = src[i];
        }
        return dst;
    }

    function _appendStringArray(string[] storage dst, string[] calldata src) internal {
        for (uint256 i = 0; i < src.length; i++) {
            dst.push(src[i]);
        }
    }

    function _appendU16Array(uint16[] storage dst, uint16[] calldata src) internal {
        for (uint256 i = 0; i < src.length; i++) {
            dst.push(src[i]);
        }
    }

    // -------------------------
    // trait selection & SVG
    // -------------------------
    function _selectIndexWeighted(uint256 seed, uint256 salt, uint16[] storage weights) internal view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            sum += weights[i];
        }
        uint256 r = uint256(keccak256(abi.encodePacked(seed, salt))) % sum;
        uint256 acc = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            acc += weights[i];
            if (r < acc) return i;
        }
        return 0;
    }

    function _attribute(string memory name, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked("{\"trait_type\":\"", name, "\",\"value\":\"", value, "\"}"));
    }

    function _escapeJson(string memory value) internal pure returns (string memory) {
        bytes memory s = bytes(value);
        bytes memory out = new bytes(s.length * 2 + 10);
        uint256 j = 0;
        for (uint256 i = 0; i < s.length; i++) {
            bytes1 c = s[i];
            if (c == 0x22) {           // "
                out[j++] = 0x5C; // '\'
                out[j++] = 0x22; // '"'
            } else if (c == 0x5C) {    // backslash
                out[j++] = 0x5C;
                out[j++] = 0x5C;
            } else if (c == 0x0A) {    // newline
                out[j++] = 0x5C;
                out[j++] = 0x6E; // 'n'
            } else if (c == 0x0D) {    // carriage return
                out[j++] = 0x5C;
                out[j++] = 0x72; // 'r'
            } else if (c == 0x09) {    // tab
                out[j++] = 0x5C;
                out[j++] = 0x74; // 't'
            } else {
                out[j++] = c;
            }
        }
        bytes memory res = new bytes(j);
        for (uint256 k = 0; k < j; k++) res[k] = out[k];
        return string(res);
    }

    function _buildDescription(
        uint256 /* seed */,
        uint256 fieldIndex,
        uint256 paradigmIndex,
        uint256 energyIndex,
        uint256 motifIndex,
        uint256 merkleWheelIndex
    ) internal view returns (string memory) {
        string memory field = fieldPhrases[fieldIndex];
        string memory paradigm = paradigmPhrases[paradigmIndex];
        string memory energy = energyPhrases[energyIndex];
        string memory motif = motifPhrases[motifIndex];
        string memory merkle = merkleWheelPhrases[merkleWheelIndex];
        return string(abi.encodePacked(field, " ", paradigm, " ", energy, " ", motif, " ", merkle));
    }

    // tokenURI
    // -------------------------
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_hasSeed[tokenId], "No seed");
        uint256 seed = _tokenSeed[tokenId];

        uint256 fieldIndex = _selectIndexWeighted(seed, 0, fieldWeights);
        uint256 paradigmIndex = _selectIndexWeighted(seed, 1, paradigmWeights);
        uint256 energyIndex = _selectIndexWeighted(seed, 2, energyWeights);
        uint256 motifIndex = _selectIndexWeighted(seed, 3, motifWeights);
        uint256 merkleWheelIndex = _selectIndexWeighted(seed, 4, merkleWheelWeights);

        string memory svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000' viewBox='0 0 1000 1000' preserveAspectRatio='xMidYMid meet'>",
            fieldSvgs[fieldIndex],
            paradigmSvgs[paradigmIndex],
            energySvgs[energyIndex],
            motifSvgs[motifIndex],
            merkleWheelSvgs[merkleWheelIndex],
            "</svg>"
        ));

        string memory imageBase64 = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
        string memory imageInlineEscaped = _escapeJson(svg);

        string memory attributes = string(abi.encodePacked(
            "[",
            _attribute("Field", fieldNames[fieldIndex]), ",",
            _attribute("Paradigm", paradigmNames[paradigmIndex]), ",",
            _attribute("Energy", energyNames[energyIndex]), ",",
            _attribute("Motif", motifNames[motifIndex]), ",",
            _attribute("Merkle Wheel", merkleWheelNames[merkleWheelIndex]),
            "]"
        ));

        string memory description = _buildDescription(seed, fieldIndex, paradigmIndex, energyIndex, motifIndex, merkleWheelIndex);

        bytes memory json = abi.encodePacked(
            "{",
            "\"name\":\"Onchain Mirage (OMG) #", tokenId.toString(), "\",",
            "\"description\":\"", _escapeJson(description), "\",",
            "\"image\":\"", imageBase64, "\",",
            "\"image_data\":\"", imageInlineEscaped, "\",",
            "\"attributes\":", attributes,
            "}"
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }
}
