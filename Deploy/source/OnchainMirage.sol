// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IOnchainMirageMetadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title OnchainMirage NFT Collection
/// @notice Fully on-chain generative NFT collection with donation-style mint.
/// @dev ETH can only enter via `mint()`. Direct ETH sends and ERC721/1155 transfers revert.
///      Owner-only functions only withdraw ETH/ERC20 that belong to the contract itself, never user balances.
contract OnchainMirage is
    ERC721,
    ERC721Enumerable,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    IERC721Receiver,
    IERC1155Receiver
{
    using SafeERC20 for IERC20;

    /// @notice Reference to metadata generator contract.
    IOnchainMirageMetadata public metadataGenerator;

    /// @notice Maximum supply of NFTs.
    uint256 public constant MAX_SUPPLY = 10000;

    /// @notice Current tokenId counter (starts at 1).
    uint256 public currentTokenId = 1;

    /// @notice Max NFTs per wallet.
    uint256 public maxPerWallet;

    /// @notice Per-wallet mint tally.
    mapping(address => uint256) public mintedPerWallet;

    /// @notice Emitted when ETH is withdrawn by the owner.
    event WithdrawETH(address to, uint256 amount);

    /// @notice Emitted when ERC20 tokens are withdrawn by the owner.
    event WithdrawERC20(address token, address to, uint256 amount);

    /// @notice Emitted when a new NFT is minted.
    event Minted(address indexed to, uint256 indexed tokenId);

    /**
     * @param metadataGeneratorAddress Metadata contract address.
     * @param royaltyReceiver Address to receive royalties.
     * @param royaltyFeeNumerator Royalty fee in basis points (max 10000 = 100%).
     * @param initialOwner Initial owner of the contract (admin).
     * @param maxPerWallet_ Max NFTs per wallet address.
     */
    constructor(
        address metadataGeneratorAddress,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator,
        address initialOwner,
        uint256 maxPerWallet_
    )
        ERC721("Onchain Mirage", "OMG")
        Ownable(initialOwner)
    {
        require(metadataGeneratorAddress != address(0), "Invalid metadata");
        require(initialOwner != address(0), "Invalid owner");
        require(royaltyFeeNumerator <= 10000, "Royalty too high");

        metadataGenerator = IOnchainMirageMetadata(metadataGeneratorAddress);
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
        maxPerWallet = maxPerWallet_;
    }

    /// @notice Public donation-style mint. ETH accepted only via this payable function.
    /// @dev Requires non-zero msg.value, enforces max supply and per-wallet limits.
    function mint() external payable nonReentrant {
        require(currentTokenId <= MAX_SUPPLY, "Sold out");
        require(mintedPerWallet[msg.sender] + 1 <= maxPerWallet, "Per-wallet limit");
        require(msg.value > 0, "Value cannot be zero");

        uint256 tokenId = currentTokenId;
        currentTokenId++;

        mintedPerWallet[msg.sender] += 1;
        _safeMint(msg.sender, tokenId);

        emit Minted(msg.sender, tokenId);

        // Assign mint-time seed in metadata contract (non-fatal if it fails)
        try
            metadataGenerator.setSeed(
                tokenId,
                uint256(
                    keccak256(
                        abi.encodePacked(
                            blockhash(block.number - 1),
                            msg.sender,
                            tokenId,
                            block.timestamp
                        )
                    )
                )
            )
        {} catch {}
    }

    /**
     * @notice Withdraw all ETH held by the contract.
     * @dev This does not touch user balances; only the contract's own ETH is transferred.
     * @param to Recipient address.
     */
    function withdrawETH(address to) external onlyOwner nonReentrant {
        require(to != address(0), "Invalid to");
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        (bool sent, ) = to.call{value: balance}("");
        require(sent, "Withdraw failed");
        emit WithdrawETH(to, balance);
    }

    /**
     * @notice Withdraw ERC20 tokens accidentally sent to this contract.
     * @dev Uses SafeERC20 for maximum safety; affects only tokens owned by this contract.
     * @param token ERC20 contract address.
     * @param to Recipient address.
     * @param amount Amount to withdraw.
     */
    function withdrawERC20(address token, address to, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(token != address(0), "Invalid token");
        require(to != address(0), "Invalid to");
        require(amount > 0, "Invalid amount");

        IERC20(token).safeTransfer(to, amount);
        emit WithdrawERC20(token, to, amount);
    }

    /// @notice Token URI forwards to metadata generator.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Nonexistent token");
        return metadataGenerator.tokenURI(tokenId);
    }

    // -----------------------------
    // Block direct ERC721 / ERC1155 receipts
    // -----------------------------

    /// @dev Revert to disallow direct ERC721 transfers to this contract.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("ERC721 not accepted");
    }

    /// @dev Revert to disallow direct ERC1155 single transfers to this contract.
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("ERC1155 not accepted");
    }

    /// @dev Revert to disallow direct ERC1155 batch transfers to this contract.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("ERC1155 not accepted");
    }

    /// @dev ERC165 support declarations: include all parent interfaces (v5 requires IERC165 explicitly).
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // --- Overrides required by Solidity / OZ v5 ---
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }
}
