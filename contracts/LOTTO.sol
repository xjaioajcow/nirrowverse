// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title LOTTO 票券代币
/// @notice 只有合约 Owner 有权限铸造（mint）新的 LOTTO 代币，初始总量为 0
/// @dev 继承 OpenZeppelin 的 ERC20 和 Ownable，实现最简单的 mint 功能
contract LOTTO is ERC20, Ownable {
    /// @dev 构造函数固定名称和符号均为 "LOTTO"
    constructor() ERC20("LOTTO", "LOTTO") {
        // 部署时总量为 0，只有 owner 可以后续 mint 补充
    }

    /// @notice 铸造新的 LOTTO 代币
    /// @param to 铸造给哪个地址
    /// @param amount 铸造数量（最小单位，18 decimals）
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice 销毁指定地址的 LOTTO 代币
    /// @param from 代币扣除地址
    /// @param amount 销毁数量（最小单位，18 decimals）
    function burn(address from, uint256 amount) external {
        if (msg.sender != from) {
            _spendAllowance(from, msg.sender, amount);
        }
        _burn(from, amount);
    }
}
