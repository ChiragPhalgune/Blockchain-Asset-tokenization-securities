// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTExchange is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    Counters.Counter private _fractionalListingIds;

    struct Listing {
        uint256 id;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    struct FractionalListing {
        uint256 id;
        address tokenContract;
        uint256 amount;
        address payable seller;
        uint256 pricePerToken;
        bool isSold;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => FractionalListing) public fractionalListings;

    event ListingCreated(uint256 indexed id, address indexed nftContract, uint256 indexed tokenId, address seller, uint256 price);
    event ListingSold(uint256 indexed id, address indexed buyer);
    event FractionalListingCreated(uint256 indexed id, address indexed tokenContract, uint256 amount, address seller, uint256 pricePerToken);
    event FractionalListingSold(uint256 indexed id, address indexed buyer, uint256 amount);

    // Constructor
    constructor(address initialOwner) Ownable(initialOwner) {}

    // Function to create a listing for an NFT
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

    // Function to buy an NFT
    function buyNFT(uint256 listingId) public payable {
        Listing storage listing = listings[listingId];
        require(!listing.isSold, "NFT is already sold");
        require(msg.value >= listing.price, "Insufficient funds");

        listing.seller.transfer(listing.price);
        IERC721(listing.nftContract).transferFrom(address(this), msg.sender, listing.tokenId);

        listing.isSold = true;

        emit ListingSold(listingId, msg.sender);
    }

    // Function to create a listing for fractional tokens
    function createFractionalListing(address tokenContract, uint256 amount, uint256 pricePerToken) public {
        require(amount > 0, "Amount must be greater than 0");
        require(pricePerToken > 0, "Price per token must be greater than 0");
        IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);

        _fractionalListingIds.increment();
        uint256 listingId = _fractionalListingIds.current();

        fractionalListings[listingId] = FractionalListing({
            id: listingId,
            tokenContract: tokenContract,
            amount: amount,
            seller: payable(msg.sender),
            pricePerToken: pricePerToken,
            isSold: false
        });

        emit FractionalListingCreated(listingId, tokenContract, amount, msg.sender, pricePerToken);
    }

    // Function to buy fractional tokens
    function buyFractionalTokens(uint256 listingId, uint256 amount) public payable {
        FractionalListing storage listing = fractionalListings[listingId];
        require(!listing.isSold, "Fractional tokens are already sold");
        require(amount <= listing.amount, "Insufficient token amount in the listing");
        uint256 totalPrice = listing.pricePerToken * amount;
        require(msg.value >= totalPrice, "Insufficient funds");

        listing.seller.transfer(totalPrice);
        IERC20(listing.tokenContract).transfer(msg.sender, amount);

        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.isSold = true;
        }

        emit FractionalListingSold(listingId, msg.sender, amount);
    }

    // Additional functions and modifications as needed...
}
