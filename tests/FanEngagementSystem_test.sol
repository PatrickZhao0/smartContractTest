// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "remix_accounts.sol";
import "../contracts/FanEngagementSystem.sol";

contract FanEngagementSystemTest is FanEngagementSystem {
    
    address acc0;
    address acc1;
    address acc2;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }

    /// #sender: account-0
    function testEarnTokens() public  {
        earnTokens(acc1, 1, "type", "proof");
        Assert.equal(fanPoints[acc1], 1, "fan points not incremented correctly");
        Assert.equal(fanToken.balanceOf(acc1), 1, "tokens not incremented correctly");
        earnTokens(acc1, 2, "type", "proof");
        Assert.equal(fanPoints[acc1], 3, "fan points not incremented correctly");
        Assert.equal(fanToken.balanceOf(acc1), 3, "tokens not incremented correctly");
    }

    /// #sender: account-1
    function testTransferTokens() public {
        transferTokens(acc2, 1);
        Assert.equal(fanPoints[acc1], 2, "fan points not decremented correctly");
        Assert.equal(fanToken.balanceOf(acc1), 2, "tokens not incremented correctly");
        Assert.equal(fanPoints[acc2], 1, "fan points not incremented correctly");
        Assert.equal(fanToken.balanceOf(acc2), 1, "tokens not incremented correctly");
    }

    /// #sender: account-1
    function testRedeemTokens() public {
        redeemTokens(1, "type");
        Reward[] memory rewards = fanRewards[acc1];
        Assert.equal(fanPoints[acc1], 1, "fan points not decremented correctly");
        Assert.equal(fanToken.balanceOf(acc1), 1, "tokens not incremented correctly");
        Assert.equal(rewards[0].rewardType, "type", "Reward Type incorrect");
    }

    /// #sender: account-0
    function testMintNFTBadge() public {
        mintNFTBadge(acc1, "testBadge");
        Assert.equal(fanBadge.ownerOf(1), acc1, "Reward Type incorrect");
    }

    /// #sender: account-1
    function testSubmitProposal() public {
        Assert.notEqual(fanToken.balanceOf(msg.sender), 0, "the balance of the sender should not be zero");
        submitProposal("test Proposal");
        Assert.equal(proposals[1].description, "test Proposal", "wrong proposal description");
    }

    /// #sender: account-2
    function testVoteOnProposal() public {
        Assert.notEqual(fanToken.balanceOf(msg.sender), 0, "the balance of the sender should not be zero");
        voteOnProposal(1);
        Assert.equal(proposals[1].votes, 1, "votes are not incremented correctly");
        Assert.ok(proposals[1].hasVoted[msg.sender], "the sender should be set 'voted' ");
    }

    /// #sender: account-0
    function testGetFanLoyaltyTier() public {
        Assert.equal(getFanLoyaltyTier(acc2), "Standard", "The tier should be standard");
        earnTokens(acc2, 99, "type", "proof");
        Assert.equal(getFanLoyaltyTier(acc2), "Bronze", "The tier should be bronze");
        earnTokens(acc2, 400, "type", "proof");
        Assert.equal(getFanLoyaltyTier(acc2), "Silver", "The tier should be silver");
        earnTokens(acc2, 500, "type", "proof");
        Assert.equal(getFanLoyaltyTier(acc2), "Gold", "The tier should be Gold");
    }

    /// #sender: account-0
    function testGetRewardHistory() public {
        string[] memory history = getRewardHistory(acc1);
        Assert.equal(history[0], "type", "The indexed 0 Acticity type is wrong");
    }
}