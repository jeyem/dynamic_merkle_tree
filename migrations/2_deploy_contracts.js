const WhiteList = artifacts.require("WhiteList")

module.exports = (deployer) => {
  deployer.deploy(WhiteList)
}