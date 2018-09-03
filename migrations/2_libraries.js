const DLL = artifacts.require('DLL')
const AuthOracle = artifacts.require('AuthOracle')
const SafeFactory = artifacts.require('SafeFactory')

module.exports = async deployer => {
    deployer.deploy(DLL)
    deployer.link(DLL, AuthOracle)
    deployer.link(DLL, SafeFactory)
}
