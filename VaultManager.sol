// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Create an error type.
error Unauthorised();

contract VaultManager {

    struct Vault {
        address owner;   // address of the owner of the vault
        uint256 balance; // The balance in a vault
    }

    // Logs whenever a vault is added
    event VaultAdded(uint256 id, address owner);

    // Logs whenever a deposit is made
    event VaultDeposit(uint256 id, address owner, uint256 amount);

    // Logs whenever a withdraw is made
    event VaultWithdraw(uint256 id, address owner, uint256 amount);

    // Vault manager stores several vaults
    Vault[] public vaults;

    // mapping for vaultsByOwner
    mapping(address => uint256[]) public vaultsByOwner;

    // Modifier onlyOwner
    modifier onlyOwner(uint256 _vaultId) {
        // Makes sure only owner can access
        if (vaults[_vaultId].owner != msg.sender) {
            revert Unauthorised();
        }
        _;
    }

    // adds a vault to the manager
    function addVault() public returns (uint256 index) {
        // 1. Create a vault struct.
        Vault memory vault = Vault({
            owner:  msg.sender, // Sets owner to message sender
            balance: 0
        });

        // 2. Adds it to the  vault array.
        vaults.push(vault);

        // 3. Get the ID of the vault.
        index = vaults.length - 1;

        // 4. Add it to the mapping, vaultsByOwner.
        vaultsByOwner[msg.sender].push(index);

        // 5. Fire off the VaultAdded event.
        emit VaultAdded(index, msg.sender);
    }

    // Deposit into a vault
    function deposit(uint256 _vaultId) public payable onlyOwner(_vaultId) {
        require(_vaultId < vaults.length, "Vault does not exist");
        vaults[_vaultId].balance += msg.value;
        emit VaultDeposit(_vaultId, msg.sender, msg.value);
    }

    // Withdraw from a vault
    function withdraw(uint256 _vaultId, uint256 amount) public onlyOwner(_vaultId) {

        require(vaults[_vaultId].balance >= amount, "Insufficient balance");
        vaults[_vaultId].balance -= amount;
        payable(msg.sender).transfer(amount);
        emit VaultWithdraw(_vaultId, msg.sender, amount);

    }

    // Returns information about a vault
    function getVault(uint256 _vaultId) public view returns (address _owner, uint256 _balance) {
        _owner = vaults[_vaultId].owner;
        _balance = vaults[_vaultId].balance;
    }

    // Returns the IDs of the tasks the users owns.
    function getVaultsLength() public view returns (uint256) {
        return vaults.length;
    }

    // Retunrs which vaults are owned by the message sender
    function getMyVaults() public view returns (uint256[] memory){
        return vaultsByOwner[msg.sender];
    }
}
