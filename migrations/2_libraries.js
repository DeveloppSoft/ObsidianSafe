const ListOnSteroids = artifacts.require('ListOnSteroids')
const AuthOracle = artifacts.require('AuthOracle')
const SafeFactory = artifacts.require('SafeFactory')

module.exports = async deployer => {
    deployer.deploy(ListOnSteroids)
    deployer.link(ListOnSteroids, AuthOracle)
    deployer.link(ListOnSteroids, SafeFactory)
}
