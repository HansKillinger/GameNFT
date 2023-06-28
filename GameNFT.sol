// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "contracts/Moderator.sol";

interface storageContractInterface{
    function createObj(uint256 tokenId, uint256 classId, string memory name) external;
}

interface settingsContractInterface{
    function getMintSettings(uint256 classId) external view returns (uint256 maxMint, uint256 price);
    function getCollectionURI() external view returns (string memory);
    function createURI(uint256 tokenId) external view returns (string memory);
}

contract GameNFT is ERC721, ERC721Enumerable, Pausable, Ownable, Moderator,ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    address public storageContract;
    address public settingsContract;
    mapping(uint256 classId => uint256 totalCount) public classMinted;

    storageContractInterface storageInterface;
    settingsContractInterface settingsInterface;

    constructor() ERC721("GameToken", "GAME") {
        _tokenIdCounter.increment();
        _pause();
    }

    function setContracts(address contractStorage, address contractSettings) public onlyOwner {
        storageContract = contractStorage;
        settingsContract = contractSettings;
        storageInterface = storageContractInterface(storageContract);
        settingsInterface = settingsContractInterface(settingsContract);
    }

    function contractURI() public view returns (string memory) {
        return settingsInterface.getCollectionURI();
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory){
        return settingsInterface.createURI(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getMintSettings(uint256 classId) public view returns (uint256 maxMint, uint256 mintPrice){
        return (settingsInterface.getMintSettings(classId));
    }

    function purchaseNFT(uint256 classId, string memory name) public payable {
        (uint256 maxMint, uint256 mintPrice) = getMintSettings(classId);
        require(maxMint > 0, "classID Doesn't Exist");
        require(msg.value == mintPrice, "Incorrect Amount of Funds Sent");
        require(classMinted[classId] < maxMint, "Max Already Minted for classId");
        safeMint(msg.sender, classId, name);
    }

    function safeMint(address to, uint256 classId, string memory name) public onlyMod {
        (uint256 maxMint,) = getMintSettings(classId);
        require(classMinted[classId] < maxMint, "Max Mint for classId");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        classMinted[classId] += 1;
        storageInterface.createObj(tokenId, classId, name);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

