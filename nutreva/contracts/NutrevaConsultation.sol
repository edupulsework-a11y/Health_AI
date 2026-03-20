// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title  NutrevaConsultation
/// @notice Flat fee per consultation call.
///         Patient pays → Doctor gets 95% → Platform keeps 5%.
///
/// HOW IT WORKS (all triggered from the Flutter Nutreva app):
///  1. User books a doctor in the app.
///  2. App calls payForConsultation(_doctorAddress) with 0.00001 ETH attached.
///  3. 95% goes to doctor instantly. 5% stays here for the platform.
///  4. Owner can call withdraw() to collect platform earnings anytime.
///
/// @dev Deploy on MegaETH Testnet — Chain: 6343 | RPC: https://carrot.megaeth.com/rpc

contract NutrevaConsultation {

    // ─── State ────────────────────────────────────────────────────────────────
    address public owner;

    /// Flat fee per call: 0.00001 ETH (for testing)
    uint256 public feePerCall = 0.00001 ether;

    /// Platform commission: 5% (500 basis points)
    uint256 public commissionBPS = 500;

    // ─── Events ───────────────────────────────────────────────────────────────
    event ConsultationPaid(
        address indexed patient,
        address indexed professional,
        uint256 amountWei,
        uint256 timestamp
    );

    // ─── Modifier ─────────────────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ─── Core ─────────────────────────────────────────────────────────────────

    /// @notice Pay for one consultation call (flat fee).
    /// @param  _professional  Doctor/nutritionist wallet address.
    function payForConsultation(address payable _professional) external payable {
        require(_professional != address(0), "Invalid address");
        require(msg.value >= feePerCall, "Insufficient payment");

        uint256 commission  = (msg.value * commissionBPS) / 10000; // 5%
        uint256 doctorShare = msg.value - commission;               // 95%

        // Send 95% to doctor using modern call pattern
        (bool sent, ) = _professional.call{value: doctorShare}("");
        require(sent, "Payment to doctor failed");
        // 5% commission stays in contract

        emit ConsultationPaid(msg.sender, _professional, msg.value, block.timestamp);
    }

    // ─── View ─────────────────────────────────────────────────────────────────

    /// @notice Returns the flat fee per call in wei.
    function getCallFee() external view returns (uint256) {
        return feePerCall;
    }

    /// @notice Returns platform commission as a percentage (e.g. 5).
    function getCommissionPercent() external view returns (uint256) {
        return commissionBPS / 100;
    }

    /// @notice Platform earnings held in contract.
    function getPlatformBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    /// @notice Update flat fee per call (owner only).
    function setCallFee(uint256 _newFeeWei) external onlyOwner {
        feePerCall = _newFeeWei;
    }

    /// @notice Update commission in basis points (max 1000 = 10%).
    function setCommission(uint256 _bps) external onlyOwner {
        require(_bps <= 1000, "Max 10%");
        commissionBPS = _bps;
    }

    /// @notice Withdraw accumulated platform fees to owner wallet.
    function withdraw() external onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "Nothing to withdraw");
        (bool sent, ) = payable(owner).call{value: bal}("");
        require(sent, "Withdraw failed");
    }

    /// @notice Transfer ownership.
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid");
        owner = _newOwner;
    }

    receive() external payable {}
}
