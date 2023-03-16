// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Moderator is Ownable {
    mapping(address => bool) public moderators;

    function isModerator(address addr)
        public
        view
        returns (bool)
        {
            if(addr == owner() || moderators[addr] == true){
                return true;
            }
            return false;
        }
    function addModerator(address addr)
        public
        onlyOwner
        {
            moderators[addr] = true;
        }
    function removeModerator(address addr)
        public
        onlyOwner
        {
            moderators[addr] = false;
        }
    
    modifier onlyMod() {
        isModerator(msg.sender);
        _;
    }
}
