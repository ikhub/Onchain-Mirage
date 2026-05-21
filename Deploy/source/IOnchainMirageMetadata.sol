// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IOnchainMirageMetadata {
    /// @notice Returns the on-chain JSON metadata for a token.
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /// @notice Sets the seed for a specific tokenId.
    /// @dev Called by the NFT contract after mint.
    function setSeed(uint256 tokenId, uint256 seed) external;
}
