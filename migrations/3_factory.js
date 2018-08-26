const SafeFactory = artifacts.require('SafeFactory')

module.exports = async deployer => {
    deployer.deploy(SafeFactory)
}
