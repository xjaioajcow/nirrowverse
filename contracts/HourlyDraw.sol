// SPDX-License-Identifier: MIT
// SPDX 许可证标识符：MIT
pragma solidity ^0.8.20;
 语用   坚固性^0.8.20；

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 进口  “@openzeppelin/contracts/token/ERC20/IERC20.sol”；
import "@openzeppelin/contracts/access/Ownable.sol";
 进口  “@openzeppelin/contracts/access/Ownable.sol”；

interface IStakeVault {
 界面  StakeVault {
    function totalEffectiveTickets() external view returns (uint256);
     功能  totalEffectiveTickets() 外部视图返回 (uint256)；
    function findWinner(uint256 r) external view returns (address);
     功能  findWinner(uint256 r) 外部视图返回（地址）；
}
 }

contract HourlyDraw is Ownable {
 合同  HourlyDraw 是可拥有的 {
    IStakeVault public stakeVault;
    StakeVault  公共权益金库；
    IERC20 public rewardToken;
    IERC20  公共奖励代币；
    address public whitelist;
     地址   公开白名单；
    address public router;
     地址   公共路由器；
    address public reserve;
     地址   公共储备；

    uint256 public round;
    uint256  公开轮；
    uint256 public lastDrawTime;
    uint256  公共最后绘制时间；
    address public lastWinner;
     地址   公开的最后获胜者；

    event Draw(address winner, uint256 round);
     事件   抽奖（获胜者地址，uint256 轮次）；

    constructor() {
     构造函数() {
    constructor(
     构造函数（
        address _vault,
         地址  _vault，
        address _rewardToken,
         地址  _rewardToken，
        address _whitelist,
         地址  _白名单，
        address _router,
         地址  _路由器，
        address _reserve
         地址  _预订
    ) {
    ) {
        stakeVault = IStakeVault(_vault);
        stakeVault = IStakeVault(_vault);
        rewardToken = IERC20(_rewardToken);
         奖励代币 = IERC20(_rewardToken);
        whitelist = _whitelist;
         白名单 = _白名单；
        router = _router;
         路由器 = _路由器；
        reserve = _reserve;
         储备 = _储备；
        round = 1;
         回合 = 1；
        lastDrawTime = block.timestamp;
         上次绘制时间 = 区块.时间戳;
    }

    function setRewardToken(address _token) external onlyOwner {
     功能  setRewardToken（地址_token）外部 onlyOwner {
        rewardToken = IERC20(_token);
         奖励代币 = IERC20(_token);
    }
    }

    function setStakeVault(address _vault) external onlyOwner {
     功能  setStakeVault（地址_vault）外部 onlyOwner {
        stakeVault = IStakeVault(_vault);
        stakeVault = IStakeVault(_vault);
    }
    }

    function setWhitelist(address _whitelist) external onlyOwner {
     功能   设置白名单（地址_whitelist）外部 onlyOwner {
        whitelist = _whitelist;
         白名单 = _白名单；
    }
    }

    function setReserve(address _reserve) external onlyOwner {
     功能  setReserve（地址_reserve）外部 onlyOwner {
        reserve = _reserve;
         储备 = _储备；
    }
    }

    /// @notice 每小时可由 owner 调用一次，用 blockhash+timestamp 简单生成伪随机
    function draw(address[] calldata participants) external onlyOwner {
     功能  draw(address[] calldata 参与者) external onlyOwner {
        require(participants.length > 0, "No participants");
         要求（参与者.长度  > 0, "无参与者");
        require(block.timestamp >= lastDrawTime + 3600, "Too soon, wait an hour");
         需要（块.时间戳  >= lastDrawTime + 3600, "太快了，等一个小时");
    function draw() external onlyOwner {
     功能  draw() 外部 onlyOwner {
        require(block.timestamp >= lastDrawTime + 3600, "Too soon");
         需要（块.时间戳  >= lastDrawTime + 3600, "太快了");

        uint256 total = stakeVault.totalEffectiveTickets();
        uint256  总计 = stakeVault.totalEffectiveTickets();
        require(total > 0, "No tickets");
         需要（总计  > 0, "没有票");

        // 用当前时间、上轮赢家和区块难度做伪随机
        uint256 rand = uint256(
        uint256 rand = uint256（
            keccak256(
            keccak256(
                abi.encodePacked(
                abi.encodePacked（
                    block.timestamp,
                     区块.时间戳，
                    block.difficulty,
                     区块难度 ，
                    block.prevrandao,
                     阻止。 prevrandao ，
                    lastWinner,
                     最后的赢家，
                    round
                     圆形的
                )
            )
        );
        （此处似有缺失，请提供更正后的文本）。

        uint256 idx = rand % participants.length;
        uint256 idx = rand % 参与者.长度 ；
        address winner = participants[idx];
         地址   获胜者 = 参与者[idx] ；
        uint256 r = rand % total;
        uint256 r = 随机数 % 总计 ；
        address winner = stakeVault.findWinner(r);
         地址   获胜者 = stakeVault.findWinner(r) ;

        lastWinner = winner;
         最后的赢家 = 赢家；
        lastDrawTime = block.timestamp;
         上次绘制时间 = 区块.时间戳;
        round += 1;
         圆形的  += 1；

        uint256 reward = rewardToken.balanceOf(address(this));
        uint256  奖励 = rewardToken.balanceOf(地址(此));
        if (reward > 0) {
         如果  （奖励 > 0）{
            rewardToken.transfer(winner, reward);
            rewardToken.transfer(获胜者，  报酬）;
        }
        }

        emit Draw(winner, round - 1);
         发射   平局（获胜者，第 1 轮）；
    }
}
