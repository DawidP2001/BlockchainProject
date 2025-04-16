// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Create an error type.
error Unauthorised();

contract VaultManager {
    enum Status {
        Todo,
        Doing,
        Done,
        Canceled
    }

    // A single Task stores three things: a name
    // (e.g., Wash the Car), a status (enumerated type),
    // and an owner (EVM-compatiable address)
    struct Vault {
        string name;
        Status status;
        address owner;
    }

    // VaultAdded event
    event VaultAdded(uint256 id, address owner);

    // VaultDeposit event
    event VaultDeposit(unit256 id, address owner, unit256 amount);

    // VaultWithdraw event
    event VaultWithdraw(unit256 id, address owner, unit256 amount);


    // Our Task Manager has an array of tasks.  The index
    // in the array identifies the task, i.e., Task #0,
    // Task #1, etc.
    Task[] public tasks;

    // Our Task Manager has a mapping from addresses to the
    // IDs of the tasks they own.
    // 0x01 -> [0, 3, 1, ...]
    // 0x02 -> [2, ...]
    // 0x03 -> [4, ...]
    // ...
    mapping(address => uint256[]) public tasksByOwner;

    // Modifier onlyOwner

    modifier onlyOwner(uint256 _vaultId) {
        // Check if the owner of the task matches the creator of the tx.  Only
        // owners can change the status of their tasks.
        if (tasks[_taskId].owner != msg.sender) {
            revert Unauthorised();
        }
        // Everything okay, continue on...
        _;
    }


    // Most important function in the contract.  It adds a new task to the
    // Task Manager.
    function addVault(
        string calldata _name,
        Status _status
    ) public returns (uint256 index) {
        // 1. Create a Task struct.
        Task memory task = Task({
            name: _name,
            status: _status,
            owner: msg.sender
        });

        // 2. Add it to the array.
        tasks.push(task);

        // 3. Get the ID of the task.
        index = tasks.length - 1;

        // 4. Add it to the mapping, tasksByOwner.
        tasksByOwner[msg.sender].push(index);

        // 5. Fire off the TaskAdded event.
        emit TaskAdded(index, _name, _status, msg.sender);
    }


    function deposit(
        uint256 _taskId,
        Status _status
    ) public onlyOwner(_taskId) {
        tasks[_taskId].status = _status;
    }

    function withdraw(
        uint256 _taskId
    ) public view returns (string memory name, Status status, address owner) {
        name = tasks[_taskId].name;
        status = tasks[_taskId].status;
        owner = tasks[_taskId].owner;
    }


    // Returns the number of tasks in the task manager.
    function getVault() public view returns (uint256) {
        return tasks.length;
    }


    // Returns the IDs of the tasks the users owns.
    function getVaultsLength() public view returns (uint256[] memory) {
        return tasksByOwner[msg.sender];
    }

    function getMyVaults() {
        
    }
}
