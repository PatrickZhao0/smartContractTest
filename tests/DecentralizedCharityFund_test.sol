// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "remix_accounts.sol";
import "../contracts/DecentralizedCharityFund.sol";

contract DecentralizedCharityFundTest is DecentralizedCharityFund{
    
    address acc0;
    address acc1;
    address acc2;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }

    /// #sender: account-0
    /// #value: 3000000000000000000
    function testDonate() public payable {
        donate();
        Assert.equal(totalDonations, msg.value, "total donation not correctly incremented");
        Assert.equal(donorVotingPower[msg.sender], msg.value, "sender's voting power not correctly incremented");
    }

    /// #sender: account-0
    /// #value: 1000000000000000000
    function testDonateContinous() public payable {
        uint256 totalDonationsThen = totalDonations;
        uint256 senderVotingPowerThen = donorVotingPower[msg.sender];
        donate();
        Assert.equal(totalDonations, totalDonationsThen + msg.value, "total donation not correctly incremented");
        Assert.equal(donorVotingPower[msg.sender], senderVotingPowerThen + msg.value, "sender's voting power not correctly incremented");
    }

    /// #sender: account-1
    /// #value: 2000000000000000000
    function testDonateOtherSender() public payable {
        uint256 totalDonationsThen = totalDonations;
        donate();
        Assert.equal(totalDonations, totalDonationsThen + msg.value, "total donation not correctly incremented");
        Assert.equal(donorVotingPower[msg.sender], msg.value, "sender's voting power not correctly incremented");
    }

    /// #sender: account-2
    function testSubmitFundRequest() public {
        submitFundingRequest(msg.sender, 4 ether, "This is a request");
        Assert.equal(fundingRequests[0].projectAddress, acc2, "project address incorrect");
        Assert.equal(fundingRequests[0].requestedAmount, 4 ether, "requested amount incorrect");
        Assert.equal(fundingRequests[0].projectDescription,  "This is a request", "project description incorrect");
        Assert.equal(fundingRequests[0].votesReceived,  0, "votesRecieved should be 0");
        Assert.equal(fundingRequests[0].isFinalized, false, "request should not be finalized");
        submitFundingRequest(msg.sender, 2 ether, "This is a request");
    }

    /// #sender: account-1
    function testVoteOnRequest() public {
        uint256 senderVotingPower = donorVotingPower[msg.sender];
        voteOnRequest(0);
        FundingRequest storage request = fundingRequests[0];
        Assert.ok(request.hasVoted[msg.sender], "the voter should have voted");
        Assert.ok(!request.isFinalized, "the request should not be finalized");
        Assert.equal(request.votesReceived, senderVotingPower, "the request should recieved sender's vote");
    }

    /// #sender: account-0
    function testAutoFinalizeRequest() public {
        voteOnRequest(0);
        FundingRequest storage request = fundingRequests[0];
        Assert.ok(request.isFinalized, "the request should be finalized");
    }

    /// #sender: account-1
    /// #value: 2000000000000000000
    function testFinalizeRequest() public payable {
        donate();
        voteOnRequest(1);
        Assert.equal(totalDonations, msg.value, "total donation not correctly incremented");
        finalizeRequest(1);
        FundingRequest storage request = fundingRequests[1];
        Assert.ok(request.isFinalized, "the request should be finalized");
    }

    function testGetFundingHistory() public {
        (address[] memory projectAddresses, uint256[] memory requestAmounts, string[] memory descriptions) = getFundingHistory();
        Assert.equal(projectAddresses[0], acc2, "project address Incorrect");
        Assert.equal(requestAmounts[0], 4 ether, "requested amount Incorrect");
        Assert.equal(descriptions[0], "This is a request", "description incorrect");
    }
}