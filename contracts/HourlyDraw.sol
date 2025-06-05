// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IStakeVault {
    /// @notice 返回当前所有用户的有效票数总和
    function totalEffectiveTickets() external view returns (uint256);

    /// @notice 根据伪随机数 r，在累积票数组里二分搜索出中奖者地址
    function findWinner(uint256 r) external view returns (address);
}

contract HourlyDraw is Ownable {
    using SafeERC20 for IERC20;

    /// 奖励代币（例如 RUM 或某 EVMTKN），
//  可以在构造时传入，也可 later 通过 setter 设置
    IERC20 public rewardToken;

    /// 关联的 StakeVault 合约，用于读取持票人的“有效票数”
//  并执行二分搜索选出 winner
    IStakeVault public stakeVault;

    /// 上一次抽奖时间戳
    uint256 public lastDrawTime;

    /// 当前轮次（从 1 开始）
    uint256 public round;

    /// 最近一位中奖者地址
    address public lastWinner;

    event Draw(address indexed winner, uint256 indexed round, uint256 reward);

    /**
     * @param _rewardToken 奖励使用的 ERC20 代币合约地址
     * @param _stakeVault  StakeVault 合约地址
     */
    constructor(address _rewardToken, address _stakeVault) {
        require(_rewardToken != address(0), "Invalid reward token");
        require(_stakeVault != address(0), "Invalid stake vault");

        rewardToken = IERC20(_rewardToken);
        stakeVault = IStakeVault(_stakeVault);
        lastDrawTime = block.timestamp;
        round = 1;
    }

    /// @notice 设置新的奖励代币地址（仅 owner）
    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "Invalid address");
        rewardToken = IERC20(_rewardToken);
    }

    /// @notice 设置新的 StakeVault 合约地址（仅 owner）
    function setStakeVault(address _stakeVault) external onlyOwner {
        require(_stakeVault != address(0), "Invalid address");
        stakeVault = IStakeVault(_stakeVault);
    }

    /**
     * @notice 每小时调用一次，选出一个持票人作为 winner，并将合约中剩余 rewardToken 全部发给他
     * @dev 使用 block.timestamp、round、lastWinner 组合 Keccak 哈希生成伪随机数
     */
    function draw() external onlyOwner {
        // 保证至少间隔 1 小时
        require(block.timestamp >= lastDrawTime + 3600, "Wait an hour");

        // 获取存入合约的奖励代币余额
        uint256 reward = rewardToken.balanceOf(address(this));
        require(reward > 0, "No rewards to distribute");

        // 获取所有持票人的有效票总数
        uint256 totalTickets = stakeVault.totalEffectiveTickets();
        require(totalTickets > 0, "No tickets staked");

        // 生成伪随机数（Keccak256）
        bytes32 hashInput = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.difficulty,
                lastWinner,
                round
            )
        );
        uint256 rand = uint256(hashInput) % totalTickets;

        // 调用 StakeVault.findWinner(uint) 执行二分搜素，返回中奖地址
        address winner = stakeVault.findWinner(rand);

        // 更新状态并发奖
        lastWinner = winner;
        lastDrawTime = block.timestamp;

        // 转账给 winner
        rewardToken.safeTransfer(winner, reward);

        emit Draw(winner, round, reward);

        // 轮次 +1
        round += 1;
    }
}
