// SPDX-License-Identifier: MIT
// Olympia CoreDAO — Soulbound Membership NFT (ERC721 + ERC721Votes + ERC5192)
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Votes} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice ERC-5192 Minimal Soulbound NFTs interface
interface IERC5192 {
    /// @notice Emitted when the locking status is changed to locked.
    event Locked(uint256 tokenId);
    /// @notice Emitted when the locking status is changed to unlocked.
    event Unlocked(uint256 tokenId);
    /// @notice Returns the locking status of a soulbound token.
    function locked(uint256 tokenId) external view returns (bool);
}

/// @title OlympiaMemberNFT
/// @notice Soulbound ERC721 with voting power for Olympia CoreDAO governance.
///         Each NFT represents a verified core maintainer. Non-transferable (mint/burn only).
///         Auto-delegates on mint so voting power is immediately active.
contract OlympiaMemberNFT is ERC721, ERC721Enumerable, ERC721Votes, Ownable, IERC5192 {
    uint256 private _nextTokenId;

    error SoulboundTransferNotAllowed();

    constructor(address initialOwner)
        ERC721("Olympia CoreDAO Member", "OLYMPIA")
        EIP712("Olympia CoreDAO Member", "1")
        Ownable(initialOwner)
    {}

    /// @notice Mint a membership NFT to a new core maintainer. Auto-delegates to self.
    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        // Auto-delegate so voting power is immediately active
        _delegate(to, to);
        emit Locked(tokenId);
        return tokenId;
    }

    /// @notice Burn (revoke) a membership NFT. Owner-only.
    function burn(uint256 tokenId) external onlyOwner {
        _update(address(0), tokenId, address(0));
    }

    // --- Soulbound (ERC-5192) ---

    /// @notice All tokens are permanently locked (soulbound).
    function locked(uint256 tokenId) external view returns (bool) {
        _requireOwned(tokenId);
        return true;
    }

    // --- Clock mode (timestamp) ---

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    // --- Required overrides (OZ diamond conflict resolution) ---

    /// @dev Soulbound enforcement + ERC721Enumerable + ERC721Votes accounting.
    ///      Reverts on transfer (only mint and burn are allowed).
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Votes)
        returns (address)
    {
        address from = _ownerOf(tokenId);

        // Soulbound: reject transfers (allow mint from address(0) and burn to address(0))
        if (from != address(0) && to != address(0)) {
            revert SoulboundTransferNotAllowed();
        }

        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 amount)
        internal
        override(ERC721, ERC721Enumerable, ERC721Votes)
    {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        // IERC5192 interface ID = 0xb45a3c0e
        return interfaceId == 0xb45a3c0e || super.supportsInterface(interfaceId);
    }
}
