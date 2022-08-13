// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Mousegame.sol";
import "./Cheese.sol";

contract LicenseStake is Ownable {


    IERC721 public immutable hunterlicense;
    IERC20 public immutable cheese;

    //Up to 5 $Cheese reward per hunt
    uint256 public cheeseRewardRange = 5;

    //10-25 exp reward per hunt
    uint256 public expMin = 10;
    uint256 public expRewardRange = 15;

    //Boosting Event
    uint256 public expModifier = 1.0;
    uint256 public cheeseModifier = 1.0;

    //Hunt time duration
    uint256 public huntTime = 900; //in seconds [60:1min] 

    constructor (IERC721 _hunterlicense, IERC20 _cheese) {
        hunterlicense = _hunterlicense;
        cheese = _cheese;
    }

    struct StakeLicense {
        address owner;
    }

    struct Player {
        uint256 timeOfLastHunt;
        uint256 timeOfNextHunt;
        uint256 unclaimedCheese;
        uint256 playerExp;

    }

    mapping(uint256 => StakeLicense) public licensedata;
    mapping(uint256 => Player) public playerdata;
    mapping(address => uint256[]) public huntHistory;
    mapping(bytes32 => uint256) hunts;

    bool isHuntOn = true;

    //////////////////  Stake Functions  ////////////////////////

    function stakeLicense (uint256 _tokenId) public {
        require(isHuntOn, "Hunting is disabled");
        require(hunterlicense.ownerOf(_tokenId) == msg.sender, "You don't own this license");
        require(hunterlicense.isApprovedForAll(msg.sender, address(this)));

        StakeLicense memory stakelicense = StakeLicense(msg.sender);
        licensedata[_tokenId] = stakelicense;

        //Reset playerdata
        uint256 timeOfNextHunt = block.timestamp + huntTime;
        Player memory player = Player(block.timestamp, timeOfNextHunt, 0, 0);
        playerdata[_tokenId] = player;

        //Transfer of License from user to contract
        hunterlicense.transferFrom(msg.sender, address(this), _tokenId);
    }

    function withdrawLicense(uint256 _tokenId) public {
        require(hunterlicense.ownerOf(_tokenId) == address(this), "License isn't staked");
        StakeLicense storage stakelicense = licensedata[_tokenId];
        require(stakelicense.owner == msg.sender, "You must be the owner of the License");

        //Reset license data
        Player storage player = playerdata[_tokenId];
        stakelicense.owner = address(0);
        player.unclaimedCheese = 0;

        //Transfer of License from contract to user
        hunterlicense.transferFrom(address(this), msg.sender, _tokenId);
    }

    function Hunt(uint256 _tokenId) public {
        require(isHuntOn, "Hunting is disabled");
        require(hunterlicense.ownerOf(_tokenId) == address(this), "No license detected");
        StakeLicense storage stakelicense = licensedata[_tokenId];
        require(stakelicense.owner == msg.sender, "You must be the owner of the License");
        Player storage player = playerdata[_tokenId];
        require(block.timestamp >= player.timeOfNextHunt, "Now is not the time to hunt yet");

        //Initiate Hunt
        player.timeOfLastHunt = block.timestamp;
        player.timeOfNextHunt = block.timestamp + huntTime;
        player.unclaimedCheese += (cheeseRewardRange * cheeseModifier);
        player.playerExp += (expRewardRange * expModifier);

    }

    function withdrawCheese(uint256 _tokenId) public {
        require(isHuntOn, "Hunting is disabled");
        require(hunterlicense.ownerOf(_tokenId) == address(this), "No license detected");
        StakeLicense storage stakelicense = licensedata[_tokenId];
        require(stakelicense.owner == msg.sender, "You must be the owner of the License");
        Player storage player = playerdata[_tokenId];

        uint256 cheeseReward = player.unclaimedCheese;
        player.unclaimedCheese = 0;

        cheese.transfer(msg.sender, cheeseReward);
    }


    ///////////////////  Read Functions  ////////////////////////

    function playerInfo(uint256 _tokenId) public view 
    returns(uint256 timeOfLastHunt, 
    uint256 timeOfNextHunt,
    uint256 unclaimedCheese,
    uint256 playerExp) {
        Player memory player = playerdata[_tokenId];
        return (player.timeOfLastHunt, player.timeOfNextHunt, player.unclaimedCheese, player.playerExp);
    }

    ///////////////////  Owner Functions ///////////////////////

    function withdraw(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function toggleHuntOn() external onlyOwner {
        isHuntOn = !isHuntOn;
    }

    function setBoostEvent(uint256 _expMod, uint256 _cheeseMod) external onlyOwner {
        expModifier = _expMod;
        cheeseModifier = _cheeseMod;
    }

    function setCheeseReward(uint256 _cheeseRewardRange) external onlyOwner {
        cheeseRewardRange = _cheeseRewardRange;
    }
    
    function setExpReward(uint256 _expMin, uint256 _expRewardRange) external onlyOwner {
        expMin = _expMin;
        expRewardRange = _expRewardRange;
    }

    function setHuntTime(uint256 _huntTime) external onlyOwner {
        huntTime = _huntTime;
    }

}