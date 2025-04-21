// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VaultManager} from "../src/VaultManager.sol";

error Unauthorised();

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
    function testInitialConditions() public view{
        uint256 vaultLength = vaultManager.getVaultsLength();
        assertEq(vaultLength, 0);
    }
    
    /*///////////////////////////////////// 
    Testing addVault function
    */////////////////////////////////////
    // Tests single added vault
    function testSingleAddVault() public{
        vm.startPrank(alice);
        uint256 vaultId = vaultManager.addVault();
        assertEq(vaultId, 0, "Vault ID should be 0");
        (address owner, uint256 balance) = vaultManager.getVault(vaultId);
        assertEq(owner, alice, "Owner should be Alice");
        assertEq(balance, 0, "Balance should be 0");
    }
    // Tests multiple added vaults
    function testMultipleAddVault() public{
        vm.startPrank(alice);
        uint256 vaultId1 = vaultManager.addVault();
        uint256 vaultId2 = vaultManager.addVault();
        assertEq(vaultId1, 0, "First Vault ID should be 0");
        assertEq(vaultId2, 1, "Second Vault ID should be 1");
        (address owner,) = vaultManager.getVault(vaultId1);
        assertEq(owner, alice, "Owner of first vault should be Alice");
        (owner,) = vaultManager.getVault(vaultId2);
        assertEq(owner, alice, "Owner of second vault should be Alice");
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
        (address owner,) = vaultManager.getVault(vaultId1);
        assertEq(owner, alice, "Owner of first vault should be Alice");
        (owner,) = vaultManager.getVault(vaultId2);
        assertEq(owner, bob, "Owner of second vault should be Bob");
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
    }
    // Tests deposit to an authorised vault
    function testDepositUnauthorised() public{
        vm.startPrank(alice); 
        vaultManager.addVault();
        uint256 vaultId = 0; 
        vm.stopPrank();
        vm.deal(bob, 1 ether); 
        vm.startPrank(bob); 
        uint256 depositAmount = 0.5 ether; 
        vm.expectRevert(Unauthorised.selector); // Expect revert for unauthorised access
        vaultManager.deposit{value: depositAmount}(vaultId);
        (, uint256 balance) = vaultManager.getVault(vaultId);
        assertEq(balance, 0, "Vault Balance should be 0");
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
        (, uint256 balance) = vaultManager.getVault(vaultId);
        // Checks balance of vault after withdrawal
        assertEq(balance, depositAmount - withdrawAmount, "Vault Balance should be 0.2 ether");
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
        (, uint256 balance) = vaultManager.getVault(vaultId);
        // Checks balance of vault after failed withdrawal
        assertEq(balance, depositAmount, "Vault Balance should be 0.5 ether");
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
        vm.expectRevert(Unauthorised.selector);
        vaultManager.withdraw(vaultId, withdrawAmount);
        (, uint256 balance) = vaultManager.getVault(vaultId);
        // Checks balance of vault after failed withdrawal
        assertEq(balance, depositAmount, "Vault Balance should be 0.5 ether");
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
    function testGetVaultsLengthNoVaults() public view{
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
        vaultManager.addVault();
        uint256[] memory aliceVaults = vaultManager.getMyVaults();
        vm.stopPrank(); 
        vm.startPrank(bob); 
        vaultManager.addVault(); 
        uint256[] memory bobVaults = vaultManager.getMyVaults();
        assertEq(aliceVaults.length, 3, "Alice should have 3 vaults");
        assertEq(bobVaults.length, 1, "Bob should have 1 vault");
        assertEq(aliceVaults[0], 0, "Alice's first vault ID should be 0");
        assertEq(bobVaults[0], 3, "Bobs's first vault ID should be 3");
    }
    // Test getMyVaults with no vaults
    function testGetMyVaultsEmpty() public{
        vm.startPrank(alice); 
        uint256[] memory aliceVaults = vaultManager.getMyVaults();
        assertEq(aliceVaults.length, 0, "Alice should have 0 vaults");
    }


    /*/////////////////////////////////////////////////////
                TESTING ADDITIONAL FEATURE SECTION
    *//////////////////////////////////////////////////////

    /*////////////////////////////////////////// 
        Testing createSubscription function
    *////////////////////////////////////////// 
    // Tests createSubscription with invalid parameters
    function testCreateSubscriptionInvalidParams() public{

    }
    // Tests createSubscription with valid parameters
    function testCreateSubscription() public{

    }
    /*////////////////////////////////////////// 
        Testing cancelSubscription function
    *////////////////////////////////////////// 
    function testCancelSubscription() public{

    }
    function testCancelSubscriptionValidParams() public{

    }
    /*////////////////////////////////////////// 
        Testing executeSubscription function
    *////////////////////////////////////////// 
    function testExecuteSubscription() public{

    }
    // This tests the case where the subscription is not active
    function testExecuteSubscriptionNotActive() public{

    }
    // This test where the first subscription is invalid
    function testExecuteSubscriptionFirstInvalid() public{

    }
    // This test where the middle subscription is invalid
    function testExecuteSubscriptionMiddleInvalid() public{

    }
    // This tests where the last subscription is invalid
    function testExecuteSubscriptionLastInvalid() public{

    }
    // This tests when a deposit has isufficient balance
    function testExecuteSubscriptionDepositInsufficientBalance() public{

    }
    // This tests when a withdraw has isufficient balance
    function testExecuteSubscriptionWithdrawInsufficientBalance() public{

    }
    // This tests when a transfer has isufficient balance
    function testExecuteSubscriptionTransferInsufficientBalance() public{

    }
    /*////////////////////////////////////////// 
        Testing getSubscription function
    *////////////////////////////////////////// 
    // Tests getSubscription with valid subscription ID
    function testGetSubscription() public{

    }
    // Test getSubscription with invalid subscription ID
    function testGetSubscriptionInvalidId() public{

    }
    /*////////////////////////////////////////// 
        Testing getMySubscriptions function
    *////////////////////////////////////////// 
    // Tests getMySubscriptions with multiple subscriptions
    function testgetMySubscriptions() public{
        
    }
    // Tests case for when mySubscriptions is empty
    function testgetMySubscriptionsEmpty() public{
        
    }
    /*////////////////////////////////////////// 
        Testing getSubscriptionsLength function
    *////////////////////////////////////////// 
    function testGetSubscriptionsLengthLowLength() public view{
        
    }
    // Tests getSubscriptionsLength with multiple subscriptions
    function testGetSubscriptionsLength() public{
        
    }
}