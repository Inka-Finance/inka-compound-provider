const InkaCompoundProvider = artifacts.require("InkaCompoundProvider");

const WETH_RINKEBY = "0xc778417E063141139Fce010982780140Aa0cD5Ab"
const WETH_KOVAN = "0xd0a1e359811322d97991e03f863a0c30c2cf029c"

module.exports = function (deployer) {
  deployer.deploy(InkaCompoundProvider, WETH_KOVAN);
};
