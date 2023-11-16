// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleWallet {
    
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    // Event to notify clients when Ether is withdrawn
    event EtherWithdrawn(address indexed _by, uint256 _amount);

    // Constructor sets the owner as the address that deployed the contract
    constructor() {
        owner = msg.sender;
    }

    // Deposit function (without this function, the contract can still receive Ether by sending to its address directly)
    function deposit() external payable onlyOwner {
        require(msg.value > 0, "Must send Ether to deposit.");
    }

    // Withdraw function, only callable by the owner
    function withdraw(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance.");
        payable(owner).transfer(_amount);
        emit EtherWithdrawn(msg.sender, _amount);
    }

    // Function to check the contract's balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

}

