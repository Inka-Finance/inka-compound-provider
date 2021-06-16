// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface ICERC20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function isCToken() external view returns (bool);
}
