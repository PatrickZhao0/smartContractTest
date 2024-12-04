// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedCharityFund {
    struct FundingRequest {
        address projectAddress;
        uint256 requestedAmount;
        string projectDescription;
        uint256 votesReceived;
        bool isFinalized;
        mapping(address => bool) hasVoted;
    }

    uint256 public totalDonations;
    mapping(address => uint256) public donorVotingPower;
    FundingRequest[] public fundingRequests;


    constructor() {
    }

    function donate() public payable {
        require(msg.value > 0, "Donation must be greater than 0");
        donorVotingPower[msg.sender] += msg.value;
        totalDonations += msg.value;
    }

    function submitFundingRequest(
        address projectAddress,
        uint256 requestedAmount,
        string memory projectDescription
    ) public returns (uint256) {
        require(projectAddress != address(0), "Invalid project address");
        require(requestedAmount > 0, "Requested amount must be greater than 0");
        require(bytes(projectDescription).length > 0, "Project description cannot be empty");

        FundingRequest storage newRequest = fundingRequests.push();
        newRequest.projectAddress = projectAddress;
        newRequest.requestedAmount = requestedAmount;
        newRequest.projectDescription = projectDescription;
        newRequest.votesReceived = 0;
        newRequest.isFinalized = false;
        return fundingRequests.length - 1;
    }

    function voteOnRequest(uint256 requestId) public returns (bool) {
        require(requestId < fundingRequests.length, "Invalid request ID");
        require(donorVotingPower[msg.sender] > 0, "No voting power");
        
        FundingRequest storage request = fundingRequests[requestId];
        require(!request.isFinalized, "Request already finalized");
        require(!request.hasVoted[msg.sender], "Already voted");

        request.votesReceived += donorVotingPower[msg.sender];
        request.hasVoted[msg.sender] = true;

        // Auto-finalize if requirements are met
        if (request.votesReceived > totalDonations / 2 && 
            address(this).balance >= request.requestedAmount) {
            finalizeRequest(requestId);
        }

        return true;
    }

    function finalizeRequest(uint256 requestId) public returns (bool) {
        require(requestId < fundingRequests.length, "Invalid request ID");
        FundingRequest storage request = fundingRequests[requestId];
        
        require(!request.isFinalized, "Request already finalized");
        require(request.votesReceived > totalDonations / 2, "Insufficient votes");
        require(address(this).balance >= request.requestedAmount, "Insufficient contract balance");

        (bool success, ) = request.projectAddress.call{value: request.requestedAmount}("");
        require(success, "Transfer failed");
        request.isFinalized = true;
        return true;
    }

    function getFundingHistory() public view returns (
        address[] memory,
        uint256[] memory,
        string[] memory
    ) {
        uint256 length = fundingRequests.length;
        address[] memory projectAddresses = new address[](length);
        uint256[] memory requestAmounts = new uint256[](length);
        string[] memory descriptions = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            if (fundingRequests[i].isFinalized) {
                FundingRequest storage request = fundingRequests[i];
                projectAddresses[i] = request.projectAddress;
                requestAmounts[i] = request.requestedAmount;
                descriptions[i] = request.projectDescription;
            }
        }

        return (projectAddresses, requestAmounts, descriptions);
    }
} 