pragma solidity =0.6.12;

import "./utils/Ownable.sol";
import './libraries/TransferHelper.sol';
import "./libraries/SafeMath.sol";

import "./eth/interfaces/IERC20.sol";
import "./eth/interfaces/ICERC20.sol";
import "./eth/interfaces/ICETH.sol";
import "./eth/interfaces/IWETH.sol";

contract InkaCompoundProvider is Ownable {
    using SafeMath for uint256;

    event InkaSupplyERC20Compound(address cToken, address underlyingToken, uint256 tokenSupply);
    event InkaSupplyETHCompound(address cToken, uint256 tokenSupply);

    address public WETH;

    constructor (address _weth) public {
        require(_weth != address(0), "InkaCompoundProvider: ZERO_WETH_ADDRESS");
        WETH = _weth;
    }

    uint256 public providerFee = 10 * 10 ** 7;
    uint256 public constant FEE_DENOMINATOR = 10 ** 10;

    function supplyEthToCompound(address payable _cEtherContract)
        public
        payable
        returns (bool)
    {
        require(_cEtherContract != address(0), "InkaCompoundProvider: ZERO_CETH_ADDRESS");
        require(msg.value > 0, "InkaCompoundProvider: TOKENS_SUPPLY_MORE_ZERO");
        ICETH cToken = ICETH(_cEtherContract);
        require(cToken.isCToken(), "InkaCompoundProvider: INVALID_CETH_ADDRESS");
        uint feeAmount = msg.value.mul(providerFee).div(FEE_DENOMINATOR);

        uint balanceBefore = cToken.balanceOf(address(this));
        cToken.mint{value: msg.value.sub(feeAmount)}();
        uint balanceAfter = cToken.balanceOf(address(this));
        TransferHelper.safeTransfer(_cEtherContract, msg.sender, balanceAfter.sub(balanceBefore));
        emit InkaSupplyETHCompound(_cEtherContract, msg.value);
        return true;
    }

    function supplyErc20ToCompound(
        address _erc20Token,
        address _cErc20Token,
        uint256 _numTokensToSupply
    ) public returns (uint) {
        return _supplyErc20ToCompound(_erc20Token, _cErc20Token, _numTokensToSupply);
    }

    function _supplyErc20ToCompound(
        address _erc20Token,
        address _cErc20Token,
        uint256 _numTokensToSupply
    ) internal returns (uint) {
        require(_erc20Token != address(0), "InkaCompoundProvider: ZERO_ERC20_ADDRESS");
        require(_cErc20Token != address(0), "InkaCompoundProvider: ZERO_CERC20_ADDRESS");
        require(_numTokensToSupply > 0, "InkaCompoundProvider: TOKENS_SUPPLY_MORE_ZERO");
        IERC20 underlying = IERC20(_erc20Token);
        ICERC20 cToken = ICERC20(_cErc20Token);
        require(cToken.isCToken(), "InkaCompoundProvider: INVALID_CTOKEN_ADDRESS");
        require(underlying.allowance(msg.sender, address(this)) >= _numTokensToSupply, "InkaCompoundProvider: TOKENS_SUPPLY_NOT_ALLOWANCE");
        uint feeAmount = _numTokensToSupply.mul(providerFee).div(FEE_DENOMINATOR);
        TransferHelper.safeTransferFrom(_erc20Token, msg.sender, address(this), _numTokensToSupply);

        if(underlying.allowance(address(this), _cErc20Token) < _numTokensToSupply) {
            TransferHelper.safeApprove(_erc20Token, _cErc20Token, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        }

        uint balanceBefore = cToken.balanceOf(address(this));
        uint mintResult = cToken.mint(_numTokensToSupply.sub(feeAmount));
        uint balanceAfter = cToken.balanceOf(address(this));
        TransferHelper.safeTransfer(_cErc20Token, msg.sender, balanceAfter.sub(balanceBefore));
        emit InkaSupplyERC20Compound(_cErc20Token, _erc20Token, _numTokensToSupply);
        return mintResult;
    }


    receive() external payable { }

    function withdraw(address token) external onlyOwner {
        if (token == WETH) {
            uint256 wethBalance = IERC20(token).balanceOf(address(this));
            if (wethBalance > 0) {
                IWETH(WETH).withdraw(wethBalance);
            }
            TransferHelper.safeTransferETH(owner(), address(this).balance);
        } else {
            TransferHelper.safeTransfer(token, owner(), IERC20(token).balanceOf(address(this)));
        }
    }

    function setFee(uint _fee) external onlyOwner {
        providerFee = _fee;
    }

    function setWETH(address _weth) external onlyOwner {
        WETH = _weth;
    }
}