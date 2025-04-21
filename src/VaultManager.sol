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
        require(_vaultId < vaults.length, "Vault does not exist"); // Explicit check for valid ID
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
    
    /*///////////////////////////////////////////
            ADDITIONAL FEATURE SECTION
    This additional feature is used for subscriptions, this allows the user to create suscriptions. 
    A user can create a deposit subscription if they have a vault for saving. The user can also create a whithdraw 
    subscription either to take money to their account or to send it to another account to pay for service. 
    The user is also able to cancel the subscription at any time. The user can also check the status of the 
    subscription. 
    *////////////////////////////////////////////
    struct Subscription {
        uint256 _vaultId; // The vault associated with the subscription
        address owner; // The owner of the subscription
        address targetAddress; // The target address for the subscription
        uint256 amount; // Amount to deposit or withdraw
        uint256 interval; // Interval for the subscription
        uint256 lastExecuted; // Timestamp of the last execution
        uint256 subType; // 0-deposit, 1-withdraw, 2-transfer
        bool isActive; // Status of the subscription
    }
    Subscription[] public subscriptions;
    mapping(address => uint256[]) public subscriptionsByOwner; // Mapping of vault ID to subscription

    event subscriptionCreated(uint256 id, address owner);
    event subscriptionCancelled(uint256 id, address owner);
    event subscriptionExecuted(uint256 id, address owner, uint256 amount);
    // Create a deposit subscription
    modifier onlySubOwner(uint256 _subId) {
        // Makes sure only owner can access
        if (subscriptions[_subId].owner != msg.sender) {
            revert Unauthorised();
        }
        _;
    }
    function createSubscription(uint256 _vaultId, uint256 amount, uint256 interval, address targetAddress, uint256 subType) public onlyOwner(_vaultId) returns (uint256 _subID){
        Subscription memory subscription = Subscription({
            _vaultId: _vaultId,
            owner: msg.sender,
            targetAddress: targetAddress,
            amount: amount,
            interval: interval,
            lastExecuted: block.timestamp,
            subType: subType,
            isActive: true
        });
        subscriptions.push(subscription);
        _subID = subscriptions.length - 1;
        vaultsByOwner[msg.sender].push(_subID);
        emit subscriptionCreated(_subID, msg.sender);
    }
    // This function cancels a subscription
    function cancelSubscription(uint256 _subID) public onlySubOwner(_subID) {
        // The subscription is cancelled by setting the isActive flag to false
        subscriptions[_subID].isActive = false;
        // Remove the subscription from the array
        subscriptions[_subID] = subscriptions[subscriptions.length - 1];
        subscriptions.pop();
        emit subscriptionCancelled(_subID, msg.sender);
    }
    // This function executes the subscriptions of a user
    function executeSubscriptions() public payable{
        // Since the subscriptions are taken from the vaultsByOwner mapping, we can loop through the subscriptions of the user
        // and don't need to use a modifer to check if the user is the owner of the subscription
        uint256[] storage subIDsArray = subscriptionsByOwner[msg.sender];
        for (uint256 i = 0; i < subIDsArray.length; i++) {
            Subscription storage subscription = subscriptions[subIDsArray[i]];
            // If subscription is active and the interval has passed -> execute the subscription
            if (subscription.isActive && block.timestamp >= subscription.lastExecuted + subscription.interval) {
                if (subscription.subType == 0) {
                    // Deposit
                    vaults[subscription._vaultId].balance += msg.value;
                    emit subscriptionExecuted(subscription._vaultId, msg.sender, subscription.amount);
                } else if (subscription.subType == 1) {
                    // Withdraw
                    require(vaults[subscription._vaultId].balance >= subscription.amount, "Insufficient balance");
                    vaults[subscription._vaultId].balance -= subscription.amount;
                    payable(subscription.owner).transfer(subscription.amount);
                    emit subscriptionExecuted(subscription._vaultId, msg.sender, subscription.amount);
                } else if (subscription.subType == 2) {
                    // Transfer
                    require(vaults[subscription._vaultId].balance >= subscription.amount, "Insufficient balance");
                    vaults[subscription._vaultId].balance -= subscription.amount;
                    payable(subscription.targetAddress).transfer(subscription.amount);
                    emit subscriptionExecuted(subscription._vaultId, msg.sender, subscription.amount);
                }
                subscription.lastExecuted = block.timestamp;
            }
        }
    }
    function getSubscription(uint256 _subId) public view returns (uint256, uint256, bool) {
        // Get subscription details
        Subscription memory subscription = subscriptions[_subId];
        return (subscription.amount, subscription.interval, subscription.isActive);
    }
    function getMySubscriptions() public view returns (uint256[] memory) {
        // Get all subscriptions for the message sender
        return subscriptionsByOwner[msg.sender];
    }
    function getSubscriptionsLength() public view returns (uint256) {
        // Get the length of the subscriptions array
        return subscriptions.length;
    }
}