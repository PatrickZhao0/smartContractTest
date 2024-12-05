// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentalAgreementManagement {
    struct RentalAgreement {
        uint256 id;
        address landlord;
        address tenant;
        uint256 rentAmount;
        uint256 startTime;
        uint256 duration;
        bool isActive;
        bool isPaid;
    }

    mapping(uint256 => RentalAgreement) public agreements;
    uint256 private nextAgreementId;

    event AgreementCreated(uint256 indexed agreementId, address indexed landlord, address indexed tenant);
    event RentPaid(uint256 indexed agreementId, address indexed tenant, uint256 amount);
    event AgreementTerminated(uint256 indexed agreementId);


    constructor() {
        nextAgreementId = 1;
    }

    function createAgreement(address tenant, uint256 rentAmount, uint256 duration) public returns (uint256) {
        require(tenant != address(0), "Invalid tenant address");
        require(rentAmount > 0, "Rent amount must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");

        uint256 agreementId = nextAgreementId;
        
        agreements[agreementId] = RentalAgreement({
            id: nextAgreementId,
            landlord: msg.sender,
            tenant: tenant,
            rentAmount: rentAmount,
            duration: duration,
            startTime: block.timestamp,
            isActive: true,
            isPaid: false
        });

        emit AgreementCreated(agreementId, msg.sender, tenant);
        nextAgreementId ++;
        return agreementId;
    }

    function payRent(uint256 agreementId) public payable {
        require(agreements[agreementId].id != 0, "Agreement does not exist");
        RentalAgreement storage agreement = agreements[agreementId];
        require(agreement.tenant == msg.sender, "Only tenant can pay rent");
        require(agreement.isActive, "Agreement is not active");
        require(block.timestamp <= agreement.startTime + agreement.duration, "Lease period has expired");

        (bool success, ) = payable(agreement.landlord).call{value: agreement.rentAmount}("");
        require(success, "Rent payment failed");
        agreement.isPaid = true;
        emit RentPaid(agreementId, msg.sender, msg.value);
    }

    function terminateAgreement(uint256 agreementId) public{
        require(msg.sender == agreements[agreementId].landlord, "Only landlord can terminate the agreement");
        require(agreements[agreementId].id != 0, "Agreement does not exist");
        RentalAgreement storage agreement = agreements[agreementId];
        require(agreement.isActive, "Agreement is already terminated");
        
        agreement.isActive = false;
        emit AgreementTerminated(agreementId);
    }

    function getAgreementStatus(uint256 agreementId) public view returns (string memory) {
        RentalAgreement storage agreement = agreements[agreementId];
        if (!agreement.isActive) {
            return "Terminated";
        }
        if (block.timestamp > agreement.startTime + agreement.duration) {
            return "Expired";
        }
        return "Active";
    }
}
