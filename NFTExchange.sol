// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract NFTExchange is Ownable, ReentrancyGuard {
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
    mapping(address => uint256) public balances;

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

        balances[listing.seller] += msg.value;
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

        balances[listing.seller] += msg.value;
        IERC20(listing.tokenContract).transfer(msg.sender, amount);

        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.isSold = true;
        }

        emit FractionalListingSold(listingId, msg.sender, amount);
    }

    function cancelListing(uint256 listingId) public {
        Listing storage listing = listings[listingId];
        require(msg.sender == listing.seller, "Only seller can cancel listing");
        require(!listing.isSold, "Listing is already sold");

        IERC721(listing.nftContract).transferFrom(address(this), listing.seller, listing.tokenId);
        
        listing.isSold = true; // or alternatively delete the listing from the mapping
        // Emit an event for listing cancellation
    }

    function updateListingPrice(uint256 listingId, uint256 newPrice) public {
        Listing storage listing = listings[listingId];
        require(msg.sender == listing.seller, "Only seller can update price");
        require(!listing.isSold, "Listing is already sold");

        listing.price = newPrice;
        // Emit an event for listing price update
    }

    struct Bid {
        uint256 amount;
        address bidder;
    }

    mapping(uint256 => Bid[]) public bids;

    function placeBid(uint256 listingId) public payable {
        require(msg.value > 0, "Bid must be greater than 0");
        bids[listingId].push(Bid({
            amount: msg.value,
            bidder: msg.sender
        }));
        // Emit an event for a new bid
    }
    
    function getListing(uint256 listingId) public view returns (Listing memory) {
        return listings[listingId];
    }

    function getBidsForListing(uint256 listingId) public view returns (Bid[] memory) {
        return bids[listingId];
    }

    // Function to withdraw funds
    function withdrawFunds() public nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No funds to withdraw");

        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    bool private locked;

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    // Function to retrieve the total number of listings
    function getTotalListings() public view returns (uint256) {
        return _listingIds.current();
    }

    // Function to retrieve all active listings
    function getActiveListings() public view returns (Listing[] memory) {
        uint256 totalListings = _listingIds.current();
        uint256 activeCount = 0;
        
        // First, count the active listings
        for (uint256 i = 1; i <= totalListings; i++) {
            if (!listings[i].isSold) {
                activeCount++;
            }
        }

        // Then, populate the array with active listings
        Listing[] memory activeListings = new Listing[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= totalListings; i++) {
            if (!listings[i].isSold) {
                activeListings[currentIndex] = listings[i];
                currentIndex++;
            }
        }

        return activeListings;
    }

    // Function to get all listing IDs
    function getAllListingIds() public view returns (uint256[] memory) {
        uint256 totalListings = _listingIds.current();
        uint256[] memory allListingIds = new uint256[](totalListings);

        for (uint256 i = 0; i < totalListings; i++) {
            allListingIds[i] = i + 1; // Adjust if your listing IDs start from a different number
        }

        return allListingIds;
    }

    // Function to get all active listing IDs
    function getAllActiveListingIds() public view returns (uint256[] memory) {
        uint256 totalListings = _listingIds.current();
        uint256 activeCount = 0;
        
        // First, determine the number of active listings
        for (uint256 i = 1; i <= totalListings; i++) {
            if (!listings[i].isSold) {
                activeCount++;
            }
        }

        // Allocate an array large enough to hold all active listing IDs
        uint256[] memory activeListingIds = new uint256[](activeCount);
        uint256 currentIndex = 0;

        // Populate the array with active listing IDs
        for (uint256 i = 1; i <= totalListings; i++) {
            if (!listings[i].isSold) {
                activeListingIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return activeListingIds;
    }

    // Function to get all sold listing IDs
    function getAllSoldListingIds() public view returns (uint256[] memory) {
        uint256 totalListings = _listingIds.current();
        uint256 soldCount = 0;
        
        // First, determine the number of sold listings
        for (uint256 i = 1; i <= totalListings; i++) {
            if (listings[i].isSold) {
                soldCount++;
            }
        }

        // Allocate an array large enough to hold all sold listing IDs
        uint256[] memory soldListingIds = new uint256[](soldCount);
        uint256 currentIndex = 0;

        // Populate the array with sold listing IDs
        for (uint256 i = 1; i <= totalListings; i++) {
            if (listings[i].isSold) {
                soldListingIds[currentIndex] = i;
                currentIndex++;
            }
        }

        return soldListingIds;
    }

    // Additional functions and modifications as needed...
}
