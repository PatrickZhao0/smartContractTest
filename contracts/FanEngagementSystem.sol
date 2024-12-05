// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Create concrete token implementations
contract FanToken is ERC20 {
    address private owner;

    constructor(address _owner) ERC20("FanToken", "FAN") {
        owner = _owner;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "Only owner can mint");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(msg.sender == owner, "Only owner can burn");
        _burn(from, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (msg.sender == owner) {
            _transfer(from, to, amount);
            return true;
        }
        return super.transferFrom(from, to, amount);
    }
}

contract FanBadge is ERC721 {
    address private owner;
    uint256 private nextTokenId;

    constructor(address _owner) ERC721("FanBadge", "FBADGE") {
        owner = _owner;
        nextTokenId = 1;
    }

    function mint(address to) public {
        require(msg.sender == owner, "Only owner can mint");
        _safeMint(to, nextTokenId);
        nextTokenId++;
    }
}

contract FanEngagementSystem is Ownable {
    FanToken public fanToken;
    FanBadge public fanBadge;

    struct Proposal {
        string description;
        uint256 votes;
        mapping(address => bool) hasVoted;
    }

    struct Reward {
        string rewardType;
        uint256 timestamp;
    }

    mapping(address => uint256) public fanPoints;
    mapping(address => Reward[]) public fanRewards;
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 private nextTokenId;

    uint256 constant BRONZE_THRESHOLD = 100;
    uint256 constant SILVER_THRESHOLD = 500;
    uint256 constant GOLD_THRESHOLD = 1000;

    event ActivitySubmitted(address fan, string activityType, string activityProof, uint256 amount);
    event NFTBadgeMinted(address fan, string badgeName, uint256 tokenId);
    event ProposalSubmitted(uint256 proposalId, string description);
    event ProposalVoted(uint256 proposalId, address voter);

    constructor() Ownable(msg.sender) {
        fanToken = new FanToken(address(this));
        fanBadge = new FanBadge(address(this));
        nextProposalId = 1;
        nextTokenId = 1;
    }

    function earnTokens(
        address fan,
        uint256 amount,
        string memory activityType,
        string memory activityProof
    ) public onlyOwner {
        fanToken.mint(fan, amount);
        fanPoints[fan] += amount;
        emit ActivitySubmitted(fan, activityType, activityProof, amount);
    }

    function transferTokens(address to, uint256 amount) public {
        require(fanToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(fanToken.transferFrom(msg.sender, to, amount), "Transfer failed");
        fanPoints[msg.sender] -= amount;
        fanPoints[to] += amount;
    }

    function redeemTokens(uint256 amount, string memory rewardType) public {
        require(fanToken.balanceOf(msg.sender) >= amount, "Insufficient balance");
        fanToken.burn(msg.sender, amount);
        fanPoints[msg.sender] -= amount;
        fanRewards[msg.sender].push(Reward(rewardType, block.timestamp));
    }

    function mintNFTBadge(address fan, string memory badgeName) public onlyOwner {
        fanBadge.mint(fan);
        emit NFTBadgeMinted(fan, badgeName, nextTokenId);
        nextTokenId++;
    }

    function submitProposal(string memory proposalDescription) public {
        require(fanToken.balanceOf(msg.sender) > 0, "Must hold tokens to submit proposal");
        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.description = proposalDescription;
        emit ProposalSubmitted(nextProposalId, proposalDescription);
        nextProposalId++;
    }

    function voteOnProposal(uint256 proposalId) public {
        require(fanToken.balanceOf(msg.sender) > 0, "Must hold tokens to vote");
        require(!proposals[proposalId].hasVoted[msg.sender], "Already voted");
        proposals[proposalId].votes++;
        proposals[proposalId].hasVoted[msg.sender] = true;
        emit ProposalVoted(proposalId, msg.sender);
    }

    function getFanLoyaltyTier(address fan) public view returns (string memory) {
        uint256 points = fanPoints[fan];
        if (points >= GOLD_THRESHOLD) return "Gold";
        if (points >= SILVER_THRESHOLD) return "Silver";
        if (points >= BRONZE_THRESHOLD) return "Bronze";
        return "Standard";
    }

    function getRewardHistory(address fan) public view returns (string[] memory) {
        Reward[] memory rewards = fanRewards[fan];
        string[] memory history = new string[](rewards.length);
        for (uint i = 0; i < rewards.length; i++) {
            history[i] = rewards[i].rewardType;
        }
        return history;
    }
}
