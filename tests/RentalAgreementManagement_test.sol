// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "remix_accounts.sol";
import "../contracts/RentalAgreementManagement.sol";

contract RentalAgreementManagementTest is RentalAgreementManagement {
    
    address acc0;
    address acc1;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
    }

    /// #sender: account-0
    function testCreateAgreement() public  {
        createAgreement(acc1, 1 ether, 6000);
        createAgreement(acc1, 1 ether, 6000);
        Assert.equal(agreements[1].id, 1, "id incorrect");
        Assert.equal(agreements[1].landlord, msg.sender, "landlord incorrect");
        Assert.equal(agreements[1].tenant, acc1, "tenant incorrect");
        Assert.equal(agreements[1].rentAmount, 1 ether, "id incorrect");
        Assert.equal(agreements[1].duration, 6000, "duration incorrect");
        Assert.equal(agreements[1].isActive, true, "the contract should be active");
        Assert.equal(agreements[1].isPaid, false, "the contract should not be paid");
    }

    /// #sender: account-1
    /// #value: 1000000000000000000
    function testPayRent() public payable {
        Assert.equal(agreements[1].tenant, msg.sender, "tenant incorrect");
        Assert.equal(agreements[1].isActive, true, "the contract should be active");
        Assert.equal(agreements[1].isPaid, false, "the contract should not be paid");
        payRent(1);
        Assert.equal(agreements[1].isPaid, true, "the contract should not be paid");
    }

    /// #sender: account-0
    function testTerminateAgreement() public payable {
        Assert.equal(agreements[1].landlord, msg.sender, "landlord incorrect");
        Assert.equal(agreements[1].isActive, true, "the contract should be active");
        terminateAgreement(1);
        Assert.equal(agreements[1].isActive, false, "the contract should be active");
    }

    /// #sender: account-0
    function testGetAgreementStatus() public {
        Assert.equal(getAgreementStatus(1), "Terminated", "The first contract should be terminated");
        Assert.equal(getAgreementStatus(2), "Active", "The third contract should be Active");
    }




}