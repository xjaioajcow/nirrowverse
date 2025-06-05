// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title RUMWL 白名单 NFT
/// @notice 只有 owner 可以 mint，每次 mint 时 tokenId = round，可用于白名单、奖品等
/// @dev 合约名称：RUMWL，代币符号：RUMWL，支持可定制 baseURI
contract RUMWL is ERC721, Ownable {
    string private _baseTokenURI;

    /// @param baseURI 项目方预设的 base URI，用于构造 metadata 链接
    constructor(string memory baseURI) ERC721("RUM-WL", "RUMWL") {
        _baseTokenURI = baseURI;
    }

    /// @notice 设置新的 baseURI（仅 owner）
    /// @param newBaseURI 新的 Base URI
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /// @notice 返回每个 token 对应的 baseURI（合并 tokenId）
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice 铸造一个白名单 NFT，tokenId = round
    /// @param to 接收地址
    /// @param round tokenId（可用当前轮次、索引等自定义）
    function mint(address to, uint256 round) external onlyOwner {
        _mint(to, round);
    }
}
