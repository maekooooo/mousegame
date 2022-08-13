// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error MaxMinted(uint256 currentSupply, uint256 attemptedAmount);

contract Cheese is Ownable, ERC20 {

    uint256 constant MAX_SUPPLY = 100000000 ether;

    event MintAction(address indexed to, uint256 amount);
    event BurnAction(address indexed to, uint256 amount);
    event BurnedFrom(address indexed to, uint256 amount);

    constructor() ERC20("Cheese Bait", "CHEESE") {
        
    }

    function mintFor(address to, uint256 amount) external onlyOwner {
        uint256 currentSupply = totalSupply();
        if(currentSupply + amount > MAX_SUPPLY) revert MaxMinted(currentSupply, amount);
        _mint(to, amount);
        emit MintAction(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit BurnAction(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
        emit BurnedFrom(account, amount);
    }
}