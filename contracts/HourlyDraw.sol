// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HourlyDraw is Ownable {
    uint256 public round;
    uint256 public lastDrawTime;
    address public lastWinner;

    event Draw(address winner, uint256 round);

    constructor() {
        round = 1;
        lastDrawTime = block.timestamp;
    }

    /// @notice 每小时可由 owner 调用一次，用 blockhash+timestamp 简单生成伪随机
    function draw(address[] calldata participants) external onlyOwner {
        require(participants.length > 0, "No participants");
        require(block.timestamp >= lastDrawTime + 3600, "Too soon, wait an hour");

        // 用当前时间、上轮赢家和区块难度做伪随机
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    lastWinner,
                    round
                )
            )
        );

        uint256 idx = rand % participants.length;
        address winner = participants[idx];

        lastWinner = winner;
        lastDrawTime = block.timestamp;
        round += 1;

        emit Draw(winner, round - 1);
    }
}
