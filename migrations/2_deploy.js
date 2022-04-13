var EventDAO = artifacts.require("./EventDAO");
var ethUtil = require('ethereumjs-util');
var sigUtil = require('eth-sig-util');

module.exports = function (deployer,accounts) {

    const tokenName = "HAKKIDAOTEST";
    const tokenSymbol = "HDAO";
    const customBaseURI_ = "#";
    const payees = ["0x77Da0Ca3012Bf3071D6162E37b2291f430a2B767"];
    const shares = [1];
    const passCardPrice = "200000000000000000";
    const passDisCardPrice = "150000000000000000";
    const vipCardPrice = "2000000000000000000";

    deployer.deploy(EventDAO, tokenName, tokenSymbol, customBaseURI_, payees, shares, passCardPrice, passDisCardPrice, vipCardPrice);

    let eventDao = EventDAO.deployed();
    const whiteList = ["0xBf98cfEbE9e826aD34fb3618079B2E2A94144Da9","0xdbaF81d491f7D470B290bCfD34D15719AF9fa765","0x61ADd26eCE377011BA42754A7c66394EBC897b18"];

    const domain = {
        name: "WhitelistToken",
        version: "1",
        chainId,
        verifyingContract: contractAddress,
      };

      const types = {
        Minter: [{ name: "wallet", type: "address" }],
      };

      var signer = accounts[0];

};

