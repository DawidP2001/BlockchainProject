// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VaultManager} from "../src/VaultManager.sol";

contract VaultManagerTest is Test {

    VaultManager public vaultManager;
    address public alice;
    address public bob;

    function setUp() public {
        vaultManager = new VaultManager();
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
    }

    /*///////////////////////////////////// 
    Testing initial conditions
    */////////////////////////////////////
    function testInitialConditions() public {
        uint256 tasksLength = vaultManager.getTasksLength();
        assertEq(tasksLength, 0);
    }
    
    /*///////////////////////////////////// 
    Testing addVault function
    */////////////////////////////////////
    // Tests single added vault
    function testSingleAddVault() public{
        vm.startPrank(alice);
        uint256 vaultId = vaultManager.addVault();
        assertEq(vaultId, 0, "Vault ID should be 0");
        assertEq(vaultManager.getVault(vaultId).owner, alice, "Owner should be Alice");
        assertEq(vaultManager.getVault(vaultId).balance, 0, "Balance should be 0");
    }
    // Tests multiple added vaults
    function testMultipleAddVault() public{
        vm.startPrank(alice);
        uint256 vaultId1 = vaultManager.addVault();
        uint256 vaultId2 = vaultManager.addVault();
        assertEq(vaultId1, 0, "First Vault ID should be 0");
        assertEq(vaultId2, 1, "Second Vault ID should be 1");
        assertEq(vaultManager.getVault(vaultId1).owner, alice, "Owner of first vault should be Alice");
        assertEq(vaultManager.getVault(vaultId2).owner, alice, "Owner of second vault should be Alice");
    }
    // Tests multiple people adding vaults
    function testMultiplePeopleAddVault() public{
        vm.startPrank(alice);
        uint256 vaultId1 = vaultManager.addVault();
        vm.stopPrank();
        vm.startPrank(bob);
        uint256 vaultId2 = vaultManager.addVault();
        assertEq(vaultId1, 0, "First Vault ID should be 0");
        assertEq(vaultId2, 1, "Second Vault ID should be 1");
        assertEq(vaultManager.getVault(vaultId1).owner, alice, "Owner of first vault should be Alice");
        assertEq(vaultManager.getVault(vaultId2).owner, bob, "Owner of second vault should be Bob");
    }
    /*///////////////////////////////////// 
    Testing deposit function
    */////////////////////////////////////
    // Tests deposit with sufficient balance
    function testDeposit() public{
        vm.deal(alice, 1 ether); 
        vm.startPrank(alice); 
        vaultManager.addVault();
        uint256 vaultId = 0; 
        uint256 depositAmount = 0.5 ether; 
        vaultManager.deposit{value: depositAmount}(vaultId);
        (address owner, uint256 balance) = vaultManager.getVault(vaultId);
        assertEq(owner, alice, "Owner should be Alice"); 
        assertEq(balance, depositAmount, "Balance should be 0.5 ether");
        assertEq(address(alice).balance, 0.5 ether - depositAmount, "Alice's balance should be 0.5 ether");
    }
    // Tests deposit with insufficient balance
    function testDepositInsufficientBalance() public{
        vm.deal(alice, 0.1 ether);
        vm.startPrank(alice); 
        vaultManager.addVault();
        uint256 vaultId = 0; 
        uint256 depositAmount = 0.5 ether;
        vm.expectRevert("Insufficient balance");
        vaultManager.deposit{value: depositAmount}(vaultId);
        assertEq(vaultManager.getVault(vaultId).balance, 0, "Vault Balance should be 0");
    }
    // Tests deposit to an authorised vault
    function testDepositUnauthorised() public{
        vm.deal(alice, 1 ether); 
        vm.startPrank(alice); 
        vaultManager.addVault();
        uint256 vaultId = 0; 
        uint256 depositAmount = 0.5 ether; 
        vm.stopPrank(); // Stop pretending to be Alice
        vm.startPrank(bob); // Start pretending to be Bob
        vm.expectRevert("Unauthorised"); // Expect revert for unauthorised access
        vaultManager.deposit{value: depositAmount}(vaultId);
        assertEq(vaultManager.getVault(vaultId).balance, 0, "Vault Balance should be 0");
    }
    /*///////////////////////////////////// 
    Testing withdraw function
    */////////////////////////////////////
    // Tests withdraw with sufficient balance
    function testWithdraw() public{
        vm.deal(alice, 1 ether); 
        vm.startPrank(alice); 
        vaultManager.addVault();
        uint256 vaultId = 0; 
        uint256 depositAmount = 0.5 ether; 
        vaultManager.deposit{value: depositAmount}(vaultId);
        uint256 withdrawAmount = 0.3 ether; 
        vaultManager.withdraw(vaultId, withdrawAmount);
        (address owner, uint256 balance) = vaultManager.getVault(vaultId);
        // Checks balance of vault after withdrawal
        assertEq(balance, depositAmount - withdrawAmount, "Vault Balance should be 0.2 ether");
        // Checks balance of Alice after withdrawal
        assertEq(address(alice).balance, 1 ether - withdrawAmount, "Alice's balance should be 0.7 ether");
    }
    // Tests withdraw with insufficient balance
    function testWithdrawInsufficientBalance() public{
        vm.deal(alice, 1 ether); 
        vm.startPrank(alice); 
        vaultManager.addVault();
        uint256 vaultId = 0; 
        uint256 depositAmount = 0.5 ether; 
        vaultManager.deposit{value: depositAmount}(vaultId);
        uint256 withdrawAmount = 0.6 ether; 
        vm.expectRevert("Insufficient balance"); // Expect revert for insufficient balance
        vaultManager.withdraw(vaultId, withdrawAmount);
        (address owner, uint256 balance) = vaultManager.getVault(vaultId);
        // Checks balance of vault after failed withdrawal
        assertEq(balance, depositAmount, "Vault Balance should be 0.5 ether");
        // Checks balance of Alice after failed withdrawal
        assertEq(address(alice).balance, 0.5 ether - depositAmount, "Alice's balance should be 0.5 ether");
    }
    // Tests withdraw from an unauthorised vault
    function testWithdrawUnauthorised() public{
        vm.deal(alice, 1 ether); 
        vm.startPrank(alice); 
        vaultManager.addVault();
        uint256 vaultId = 0; 
        uint256 depositAmount = 0.5 ether; 
        vaultManager.deposit{value: depositAmount}(vaultId);
        uint256 withdrawAmount = 0.3 ether; 
        vm.stopPrank(); 
        vm.startPrank(bob);
        vm.expectRevert("Unauthorised");
        vaultManager.withdraw(vaultId, withdrawAmount);
        (address owner, uint256 balance) = vaultManager.getVault(vaultId);
        // Checks balance of vault after failed withdrawal
        assertEq(balance, depositAmount, "Vault Balance should be 0.5 ether");
        // Checks balance of Alice after failed withdrawal
        assertrEq(address(alice).balance, 0.5 ether - depositAmount, "Alice's balance should be 0.5 ether");
        // Checks balance of Bob after failed withdrawal
        assertEq(address(bob).balance, 0, "Bob's balance should be 0 ether");
    }
    /*///////////////////////////////////// 
    Testing getVault function
    */////////////////////////////////////
    // Tests getVault with valid vault ID
    function testGetVault() public{
        vm.startPrank(alice); 
        uint256 vaultId = vaultManager.addVault(); 
        (address owner, uint256 balance) = vaultManager.getVault(vaultId);
        assertEq(owner, alice, "Owner should be Alice"); 
        assertEq(balance, 0, "Balance should be 0");
    }
    // Tests getVault with invalid vault ID
    function testGetVaultInvalidId() public{
        vm.startPrank(alice); 
        uint256 vaultId = 0;
        // This tells the vm to expect a fail test case
        vm.expectRevert("Vault does not exist"); 
        vaultManager.getVault(vaultId);
    }
    /*///////////////////////////////////// 
    Testing getVaultsLength function
    */////////////////////////////////////
    // Tests getVaultsLength with no vaults
    function testGetVaultsLengthNoVaults() public{
        uint256 vaultsLength = vaultManager.getVaultsLength();
        assertEq(vaultsLength, 0, "Vaults length should be 0");
    }
    // Tests getVaultsLength with multiple vaults
    function testGetVaultsLength() public{
        vm.startPrank(alice); 
        vaultManager.addVault(); 
        vaultManager.addVault(); 
        uint256 vaultsLength = vaultManager.getVaultsLength();
        assertEq(vaultsLength, 2, "Vaults length should be 2");
    }
    /*///////////////////////////////////// 
    Testing getMyVaults function
    */////////////////////////////////////
    // Test getMyVaults with multiple vaults
    function testGetMyVaults() public{
        vm.startPrank(alice); 
        vaultManager.addVault(); 
        vaultManager.addVault(); 
        vm.stopPrank(); 
        vm.startPrank(bob); 
        vaultManager.addVault(); 
        uint256[] memory aliceVaults = vaultManager.getMyVaults();
        uint256[] memory bobVaults = vaultManager.getMyVaults();
        assertEq(aliceVaults.length, 2, "Alice should have 2 vaults");
        assertEq(bobVaults.length, 1, "Bob should have 1 vault");
        assertEq(aliceVaults[0], 0, "Alice's first vault ID should be 0");
    }
    // Test getMyVaults with no vaults
    function testGetMyVaultsEmpty() public{
        vm.startPrank(alice); 
        uint256[] memory aliceVaults = vaultManager.getMyVaults();
        assertEq(aliceVaults.length, 0, "Alice should have 0 vaults");
    }
}
