// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "contracts/Moderator.sol";

struct objClassSettings{
    string className;
    uint256[] features;
    uint256[] minStats;
    uint256[] maxStats;
    uint256 maxMint;
    uint256 price;
    string imageURI;
    string desc;
}

struct collectionSettings{
    string name;
    string desc;
    string external_link;
    string image;
    string fee_recipient;
    uint256 fee; // 100 = 1%
}

interface storageContractInterface{
    function getObj(uint256 tokenId) external view returns (string memory name, uint256 classId, uint256 exp, uint256[] memory statsArray);
}

contract GameSettings is Ownable, Moderator {
    using Strings for uint256;

    address public storageContract;
    mapping(uint256 statNum => string) private statNames;
    mapping(uint256 featureNum => string) private featureNames;
    mapping(uint256 classId => objClassSettings) private objSettings;
    uint256 public numStats = 4;
    string public collectionURI;
    string public featuresName = "Ability";
    collectionSettings public settings;

    storageContractInterface storageInterface;


    function setContracts(address contractStorage) public onlyOwner {
        storageContract = contractStorage;
        storageInterface = storageContractInterface(storageContract);
    }


    function setObjSettings(uint256 classId, uint256 price, string memory className, uint256 maxMint, string memory imageURI,
      string memory description, uint[] memory features, uint[] memory minStats, uint[] memory maxStats) public onlyMod {
        objSettings[classId].className = className;
        objSettings[classId].maxMint = maxMint;
        objSettings[classId].price = price;
        objSettings[classId].imageURI = imageURI;
        objSettings[classId].desc = description;
        setFeatures(classId, features);
        setMaxStats(classId, maxStats);
        setMinStats(classId, minStats);
    }


    function getCollectionURI() public view returns (string memory){return collectionURI;}


    function getObjStatsSettings(uint256 classId) public view returns(uint256, uint256[] memory, uint256[] memory){
        return (numStats, getMinStats(classId), getMaxStats(classId));
    }


    function getMintSettings(uint256 classId) public view returns (uint256 maxMint, uint256 price){
        return (objSettings[classId].maxMint, objSettings[classId].price);
    }


    function setMinStats(uint256 classId, uint[] memory minStats) public onlyMod {
        require(minStats.length == numStats, "Incorrect Number of minStats");
        objSettings[classId].minStats = new uint256[](numStats);
        for(uint i=0;i<numStats;i++){objSettings[classId].minStats[i] = minStats[i];}
    }


    function setMaxStats(uint256 classId, uint[] memory maxStats) public onlyMod {
        require(maxStats.length == numStats, "Incorrect Number of maxStats");
        objSettings[classId].maxStats = new uint256[](numStats);
        for(uint i=0;i<numStats;i++){objSettings[classId].maxStats[i] = maxStats[i];}
    }


    function setFeatures(uint256 classId, uint[] memory features) public onlyMod {
        objSettings[classId].features = new uint256[](features.length);
        for(uint256 i=0; i < features.length; i++){objSettings[classId].features[i] = features[i];}
    }


    function getMinStats(uint256 classId) public view returns (uint[] memory){
        return objSettings[classId].minStats;
    }


    function getMaxStats(uint256 classId) public view returns (uint[] memory){
        return objSettings[classId].maxStats;
    }


    function getFeatures(uint256 classId) public view returns (uint[] memory stats){
        return objSettings[classId].features;
    }


    function setStatNames(string[] memory newNames) public onlyMod {
        for(uint256 i=0; i < newNames.length; i++){statNames[i+1] = newNames[i];}
    }


    function setFeatureNames(string[] memory newNames) public onlyMod {
        for(uint256 i=0; i < newNames.length; i++){featureNames[i+1] = newNames[i];}
    }


    function setnumStats(uint256 newNum) public onlyMod {numStats = newNum;}


    function setCollectionMetadata(string memory name, string memory desc, string memory image, string memory external_link, uint256 fee_percent, string memory fee_recipient) public onlyOwner{
          settings.name = name;
          settings.desc = desc;
          settings.image = image;
          settings.external_link = external_link;
          settings.fee = fee_percent * 100;
          settings.fee_recipient = fee_recipient;
          createCollectionURI();
      }
    
    
    function createCollectionURI() private onlyOwner {
            
            bytes memory dataURI = abi.encodePacked(
                '{',
                    '"name": "', settings.name, '",',
                    '"description": "', settings.desc, '",',
                    '"image": "', settings.image, '",',
                    '"external_link": "', settings.external_link, '",',
                    '"seller_fee_basis_points": ', settings.fee.toString(), ',',
                    '"fee_recipient": "', settings.fee_recipient, '"',
                '}'
            );
            collectionURI = string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
        }

    function createURI(uint256 tokenId) public view returns (string memory){
            (string memory name, uint256 classId, uint256 exp, uint256[] memory stats) = storageInterface.getObj(tokenId);
            uint256[] memory maxStats = getMaxStats(classId);
            string memory attributes = string(abi.encodePacked('{"trait_type":"exp","value": ', exp.toString(),'},'));
            bytes memory temp;
            attributes = string.concat(attributes, string(temp));
            for(uint i = 0;i<numStats;i++){
                temp = abi.encodePacked('{"trait_type":"', statNames[i], '","value": ', stats[i].toString(), ',"max_value": ', maxStats[i].toString() ,'},');
                attributes = string.concat(attributes, string(temp));
                }
            temp = abi.encodePacked('{"trait_type":"class","value": "', objSettings[classId].className,'"}');
            attributes = string.concat(attributes, string(temp));
            bytes memory dataURI = abi.encodePacked(
                '{',
                    '"name": "', name, '",',
                    '"description": "', objSettings[classId].desc, '",',
                    '"external_url": "', settings.external_link, '",',
                    '"image": "', objSettings[classId].imageURI, '",',
                    '"attributes":[', attributes, ']',        
                '}'
            );
            return string(abi.encodePacked("data:application/json;base64,",Base64.encode(dataURI)));}
    
}
