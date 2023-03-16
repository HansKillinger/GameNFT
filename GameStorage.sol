// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/Moderator.sol";


struct objStats{
    uint256 classId;
    string name;
    uint256 exp;
    uint256[] stats;
}

interface settingsContractInterface{
    function getObjStatsSettings(uint256 classId) external view returns(uint256, uint256[] memory, uint256[] memory);
}

contract GameStorage is Ownable, Moderator {

    address public settingsContract;
    mapping(uint256 tokenId => objStats) public stats;

    settingsContractInterface settingsInterface;

    function setContracts(address contractSettings) public onlyOwner {
        settingsContract = contractSettings;
        settingsInterface = settingsContractInterface(settingsContract);
    }
    
    function getObj(uint256 tokenId) public view returns (string memory name, uint256 classId, uint256 exp, uint256[] memory statsArray){
        return (stats[tokenId].name, stats[tokenId].classId, stats[tokenId].exp, stats[tokenId].stats);
    }
    
    function createObj(uint256 tokenId, uint256 classId, string memory name) public onlyMod {
        require(stats[tokenId].classId == 0, "Obj Exists");
        stats[tokenId].classId = classId;
        stats[tokenId].name = name;
        stats[tokenId].exp = 1;
        rollStats(tokenId, classId);
    }

    function randomStat(uint256 statNum, uint256 min, uint256 max) private view returns (uint) {
        uint256 mod = max - min + 1;
        uint256 result = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, statNum))) % mod;
        return result + min;
    }

    function rollStats(uint256 tokenId, uint256 classId) private onlyMod {
        (uint256 numStats, uint256[] memory minStats, uint256[] memory maxStats) = settingsInterface.getObjStatsSettings(classId);
        stats[tokenId].stats = new uint256[](numStats);
        for (uint i = 0; i< numStats; i++){
            stats[tokenId].stats[i] = randomStat(i, minStats[i], maxStats[i]);
        }
    }

    function setStat(uint256 tokenId, uint256 statNum, uint256 newStat) public onlyMod {
            (, uint256[] memory minStats, uint256[] memory maxStats) = settingsInterface.getObjStatsSettings(stats[tokenId].classId);
            require(newStat >= minStats[statNum], "Exceeds Max Stat");
            require(newStat <= maxStats[statNum], "Below Min Stat");
            stats[tokenId].stats[statNum] = newStat;
        }
    
    function setName(uint256 tokenId, string memory newName) public onlyMod {stats[tokenId].name = newName;}

    function setExp(uint256 tokenId, uint256 newExp) public onlyMod {stats[tokenId].exp = newExp;}

    function setClassId(uint256 tokenId, uint256 newClassId) public onlyMod {stats[tokenId].classId = newClassId;}
}
