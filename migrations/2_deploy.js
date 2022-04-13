const EventDao = artifacts.require("EventDao");

module.exports = function (deployer) {
    
  await deployer.deploy(EventDao,
    
    );
  const token = await EventDao.deployed();


};