// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FractionalOwnershipToken is ERC20 {
    address public nftOwner;
    address public nftContractAddress;
    uint256 public nftTokenId;
    uint256 public totalShares;
    bool public isNFTLinked; // Flag to indicate if the NFT details are set

    // Event to log the setup of fractional tokens with the NFT details
    event FractionalTokensSetup(address indexed nftContractAddress, uint256 indexed nftTokenId, uint256 totalShares);

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        nftOwner = msg.sender;
    }

    // Function to setup fractional tokens linked to the NFT
    function setupFractionalToken(
        address _nftContractAddress,
        uint256 _nftTokenId,
        uint256 _totalShares
    ) public {
        require(msg.sender == nftOwner, "Caller is not the NFT owner");
        require(!isNFTLinked, "Fractional token already setup"); // Prevent re-setup if already configured
        nftContractAddress = _nftContractAddress;
        nftTokenId = _nftTokenId;
        totalShares = _totalShares;
        isNFTLinked = true; // Set the flag to true as NFT details are now linked

        // Emit an event to log the setup details
        emit FractionalTokensSetup(_nftContractAddress, _nftTokenId, _totalShares);

        _mint(msg.sender, _totalShares);  // Mint all fractional tokens to the NFT owner
    }

    // Public view function to verify the linked NFT details
    function getLinkedNFTDetails() public view returns (address, uint256) {
        require(isNFTLinked, "No NFT linked");
        return (nftContractAddress, nftTokenId);
    }

    // Function to transfer NFT ownership in the event of a buyout or other reason
    function changeNFTOwnership(address newOwner) public {
        require(msg.sender == nftOwner, "Caller is not the NFT owner");
        nftOwner = newOwner;
    }

    // Additional functions to manage fractional ownership can be added here
    // ...
}
