const InkaCompoundProvider = artifacts.require("InkaCompoundProvider");

const WETH = "0xc778417E063141139Fce010982780140Aa0cD5Ab"

module.exports = function (deployer) {
  deployer.deploy(InkaCompoundProvider, WETH);
};
