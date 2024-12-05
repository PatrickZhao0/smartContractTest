// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "remix_accounts.sol";
import "../contracts/DecentralizedAuctionHouse.sol";

contract DecentralizedAuctionHouseTest is DecentralizedAuctionHouse{
    
    address acc0;
    address acc1;
    address acc2;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }

    /// #sender: account-0
    function testCreateAuction() public {
        Assert.equal(msg.sender, acc0, 'wrong sender');
        createAuction("Test Item", 1 ether, 3600);
        (string memory itemName, uint256 reservePrice, uint256 endTime, bool isActive) = getAuctionDetails(1);

        Assert.equal(itemName, "Test Item", "Item name should be 'Test Item'");
        Assert.equal(reservePrice, 1 ether, "Reserve price should be 1 ether");
        Assert.ok(isActive, "Auction should be active");
        Assert.greaterThan(endTime, block.timestamp, "Auction end time should be in the future");
    }

    /// #sender: account-1
    /// #value: 2000000000000000000
    function testPlaceBid() public payable {
        Assert.equal(msg.sender, acc1, 'wrong sender');
        Assert.equal(msg.value, 2 ether, 'value should be 2 ether');
        placeBid(1, 2 ether);
        
        Assert.equal(auctions[1].highestBid, 2 ether, "Highest bid should be 2 ether");
        Assert.equal(auctions[1].highestBidder, acc1, "Highest bidder should be this contract");
    }

    /// #sender: account-2
    /// #value: 3000000000000000000
    function testPlaceBid2() public payable {
        Assert.equal(msg.sender, acc2, 'wrong sender');
        Assert.equal(msg.value, 3 ether, 'value should be 2 ether');
        placeBid(1, 3 ether);
        
        Assert.equal(auctions[1].highestBid, 3 ether, "Highest bid should be 3 ether");
        Assert.equal(auctions[1].highestBidder, acc2, "Highest bidder should be this contract");
    }

    /// #sender: account-1
    function testWithdrawBid() public  {
        Assert.equal(msg.sender, acc1, 'wrong sender');
        Assert.equal(bids[1][msg.sender], 2 ether, "the bid should be 2 ether");
        withdrawBid(1);
        Assert.equal(bids[1][msg.sender], 0 ether, "not withdrawed");
    } 

    /// #sender: account-0
    function testFinalizeAuction() public {
       auctions[1].endTime = block.timestamp - 1;
       finalizeAuction(1);
       Assert.ok(!auctions[1].isActive, "Auction should be finalized and inactive");
    }

    /// #sender: account-0
    function testGetAuctionDetails() public {
        (string memory itemName, uint256 reservePrice, uint256 endTime, bool isActive) =  getAuctionDetails(1);
        Assert.equal(itemName, auctions[1].itemName, "item name wrong");
        Assert.equal(reservePrice, auctions[1].reservePrice, "item name wrong");
        Assert.equal(endTime, auctions[1].endTime, "item name wrong");
        Assert.equal(isActive, auctions[1].isActive, "item name wrong");
    }



    // Fallback function to receive Ether
    receive() external payable {}
}