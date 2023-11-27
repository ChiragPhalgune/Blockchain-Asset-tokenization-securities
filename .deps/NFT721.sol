// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/0xcert/ethereum-erc721/src/contracts/tokens/nf-token-metadata.sol";
import "https://github.com/0xcert/ethereum-erc721/src/contracts/ownership/ownable.sol";

contract newNFT is NFTokenMetadata, Ownable {
    address public fractionalTokensContract;

    constructor() {
        // Define NFT name and symbol
        nftName = "SectionTest NFT";
        nftSymbol = "STNF";
    }

    // Event to log the setting of fractional tokens contract address
    event FractionalTokensContractSet(address indexed fractionalTokensContract);

    // Function to set the fractional tokens contract address
    function setFractionalTokens(address _fractionalTokensContract) external onlyOwner {
        fractionalTokensContract = _fractionalTokensContract;

        // Emit an event to log the setting of the fractional tokens contract address
        emit FractionalTokensContractSet(_fractionalTokensContract);
    }

    function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
        super._mint(_to, _tokenId);
        super._setTokenUri(_tokenId, _uri);
    }
}
