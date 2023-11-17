//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTExchange is Ownable(0xdD632BD9e1d6B6996861a359d384881Fc66d436B) {
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    struct Listing {
        uint256 id;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    mapping(uint256 => Listing) public listings;

    event ListingCreated(uint256 indexed id, address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price);
    event ListingSold(uint256 indexed id, address indexed buyer);

function createListing(address nftContract, uint256 tokenId, uint256 price) public {
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    
    _listingIds.increment();
    uint256 listingId = _listingIds.current();

    listings[listingId] = Listing({
        id: listingId,
        nftContract: nftContract,
        tokenId: tokenId,
        seller: payable(msg.sender),
        price: price,
        isSold: false
    });

    emit ListingCreated(listingId, nftContract, tokenId, msg.sender, price);
}
function buyNFT(uint256 listingId) public payable {
    Listing storage listing = listings[listingId];
    require(!listing.isSold, "NFT is already sold");
    require(msg.value >= listing.price, "Insufficient funds");

    listing.seller.transfer(listing.price);
    IERC721(listing.nftContract).transferFrom(address(this), msg.sender, listing.tokenId);

    listing.isSold = true;

    emit ListingSold(listingId, msg.sender);
}
}