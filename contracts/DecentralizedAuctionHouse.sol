// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedAuctionHouse {
    struct Auction {
        uint256 id;
        string itemName;
        address payable seller;
        uint256 reservePrice;
        uint256 endTime;
        bool isActive;
        uint256 highestBid;
        address highestBidder;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 private nextAuctionId;

    mapping(uint256 => mapping(address => uint256)) public bids;
    
    constructor() {
        nextAuctionId = 1;
    }

    function createAuction(string memory itemName, uint256 reservePrice, uint256 auctionDuration) external {
        require(reservePrice > 0, "Reserve price must be greater than 0");
        require(auctionDuration > 0, "Auction duration must be greater than 0");
        auctions[nextAuctionId] = Auction({
            id: nextAuctionId,
            itemName: itemName,
            seller: payable(msg.sender),
            reservePrice: reservePrice,
            endTime: block.timestamp + auctionDuration,
            isActive: true,
            highestBid: 0,
            highestBidder: address(0)
        });
        nextAuctionId++;
    }

    function placeBid(uint256 auctionId, uint256 bidAmount) external payable {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(bidAmount > auction.reservePrice, "Bid amount must be greater than reserve price");
        require(bidAmount > auction.highestBid, "Bid must be higher than the current highest bid");
        require(msg.value == bidAmount, "Sent value must match bid amount");
        auction.highestBid = bidAmount;
        auction.highestBidder = msg.sender;
        bids[auctionId][msg.sender] = bidAmount;
    }

    function withdrawBid(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        require(block.timestamp <= auction.endTime, "Auction has ended");
        require(msg.sender != auction.highestBidder, "The highest bidder cannot withdraw");
        uint256 bidAmount = bids[auctionId][msg.sender];
        require(bidAmount > 0, "No bid to withdraw");

        bids[auctionId][msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: bidAmount}("");
        require(success, "Failed to send Ether");

    }

    function finalizeAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        require(block.timestamp >= auction.endTime, "Auction has not ended");
        require(auction.highestBid >= auction.reservePrice, "Reserve price not met");
        require(auction.highestBidder != address(0), "No valid bids placed");
        
        auction.isActive = false;
        
        (bool success, ) = payable(auction.seller).call{value: auction.highestBid}("");
        require(success, "Failed to send Ether");
    }

    function getAuctionDetails(uint256 auctionId) external view returns (
        string memory itemName,
        uint256 reservePrice,
        uint256 endTime,
        bool isActive
    ) {
        Auction storage auction = auctions[auctionId];
        return (
            auction.itemName,
            auction.reservePrice,
            auction.endTime,
            auction.isActive
        );
    }

}
