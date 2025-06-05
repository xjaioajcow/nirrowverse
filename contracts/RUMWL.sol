// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title RUMWL 白名单 NFT
/// @notice 只有 owner 可以 mint，每次 mint 时 tokenId = round，可用于白名单、奖品等
/// @dev 合约名称为 RUMWL，代币符号为 RUMWL
contract RUMWL is ERC721, Ownable {
    constructor() ERC721("RUM-WL", "RUMWL") {}

    /// @notice 铸造一个 NFT，只有 owner 可以操作
    /// @param to 接收地址
    /// @param round tokenId = round（每一轮独立）
    function mint(address to, uint256 round) external onlyOwner {
        _mint(to, round);
    }
}
