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
        vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        uint256 vaultId = 0; // Alice's vault ID
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        uint256 subType = 3; // Invalid subscription type
        vm.expectRevert("Invalid subscription type"); // Expect revert for invalid subscription type
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
  }
    // Tests createSubscription with valid parameters
    function testCreateSubscription() public{
        vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        uint256 vaultId = 0; // Alice's vault ID
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        uint256 subType = 2;
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        uint256 subID = 0;
        (uint256 id, address owner, uint256 amount2, uint256 interval2, address recipient2, uint256 subType2, bool active) = vaultManager.getSubscription(subID);
        assertEq(id, 0, "Vault ID should be 0");
        assertEq(owner, alice, "Owner should be Alice"); 
        assertEq(amount2, 0.5 ether, "Amount should be 0.5 ether");
        assertEq(interval2, 1 weeks, "Interval should be 1 weeks");
        assertEq(recipient2, bob, "Recipient should be Bob");
        assertEq(subType2, 2, "Subscription type should be 2-Transfer");
        assertEq(active, true, "Subscription should be active");
    }
    /*////////////////////////////////////////// 
        Testing cancelSubscription function
    *////////////////////////////////////////// 
    function testCancelSubscription() public{
        vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        uint256 vaultId = 0; // Alice's vault ID
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        uint256 subType = 2;
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        uint256 subID = 0;
        vaultManager.cancelSubscription(subID); // Cancel the subscription
        uint256 length = vaultManager.getSubscriptionsLength(); // Get the length of subscriptions
        assertEq(length, 0, "Subscription length should be 0 after cancellation");
    }
    function testCancelSubscriptionInValidParams() public{
        vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        uint256 vaultId = 0; // Alice's vault ID
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        uint256 subType = 2;
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        uint256 subID = 1;
        vm.expectRevert("Subscription does not exist"); // Expect revert for non-existent subscription
        vaultManager.cancelSubscription(subID); // Cancel the subscription
    }
    function testCancelSubscriptionUnauthorised() public{
        vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        uint256 vaultId = 0; // Alice's vault ID
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        uint256 subType = 2;
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        uint256 subID = 0;
        vm.stopPrank(); 
        vm.startPrank(bob); 
        vm.expectRevert(Unauthorised.selector); // Expect revert for unauthorised access
        vaultManager.cancelSubscription(subID); // Cancel the subscription
    }
    /*////////////////////////////////////////// 
        Testing executeSubscription function
    *//////////////////////////////////////////
    function setUpSubscriptions() public{
        vm.deal(alice, 20 ether);
        vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        vaultManager.addVault(); // Alice adds a vault
        vaultManager.deposit{value: 0.5 ether}(1); // Alice deposits 0.5 ether into vault 1
        vaultManager.addVault(); // Alice adds a vault
        vaultManager.deposit{value: 0.5 ether}(2); // Alice deposits 0.5 ether into vault 2
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        vaultManager.createSubscription(0, amount, interval, address(0), 0); // Deposit subscription
        vaultManager.createSubscription(1, amount, interval, address(0), 1); // Withdraw subscription  
        vaultManager.createSubscription(2, amount, interval, recipient, 2); // Transfer subscription
        vm.warp(2 weeks); // Move forward in time by 1 week
    }
    function testexecuteSubscriptions() public{
        setUpSubscriptions(); // Set up subscriptions
        vaultManager.executeSubscriptions{value: 10 ether}(); 
        (, uint256 balance) = vaultManager.getVault(0); // Get vault 0 details
        assertEq(balance, 0.5 ether, "Vault 0 balance should be 0.5 ether after deposit subscription execution");
        (, balance) = vaultManager.getVault(1); // Get vault 1 details
        assertEq(balance, 0 ether, "Vault 1 balance should be 0 ether after withdraw subscription execution");
        (, balance) = vaultManager.getVault(2); // Get vault 2 details
        assertEq(balance, 0 ether, "Vault 2 balance should be 0 ether after transfer subscription execution");
    }
    // This tests when a deposit has isufficient balance
    function testExecuteSubscriptionDepositInsufficientBalance() public{
        setUpSubscriptions(); // Set up subscriptions
        vaultManager.executeSubscriptions{value: 0.2 ether}(); 
        (, uint256 balance) = vaultManager.getVault(0); // Get vault 0 details
        assertEq(balance, 0, "Vault 0 balance should be 0 ether after deposit subscription execution due to insufficient balance");
        (, balance) = vaultManager.getVault(1); // Get vault 1 details
        assertEq(balance, 0 ether, "Vault 1 balance should be 0 ether after withdraw subscription execution");
        (, balance) = vaultManager.getVault(2); // Get vault 2 details
        assertEq(balance, 0 ether, "Vault 2 balance should be 0 ether after transfer subscription execution");
    }
    // This tests when a withdraw has isufficient balance
    function testExecuteSubscriptionWithdrawInsufficientBalance() public{
        setUpSubscriptions(); // Set up subscriptions
        vaultManager.withdraw(1, 0.1 ether); // Withdraw from vault 1
        vaultManager.executeSubscriptions{value: 2 ether}(); 
        (, uint256 balance) = vaultManager.getVault(0); // Get vault 0 details
        assertEq(balance, 0.5 ether, "Vault 0 balance should be 0 ether after deposit subscription execution");
        (, balance) = vaultManager.getVault(1); // Get vault 1 details
        assertEq(balance, 0.4 ether, "Vault 1 balance should be 0.4 ether after withdraw subscription execution since it has insufficient funds");
        (, balance) = vaultManager.getVault(2); // Get vault 2 details
        assertEq(balance, 0 ether, "Vault 2 balance should be 0 ether after transfer subscription execution");
    }
    // This tests when a transfer has isufficient balance
    function testExecuteSubscriptionTransferInsufficientBalance() public{
        setUpSubscriptions(); // Set up subscriptions
        vaultManager.withdraw(2, 0.1 ether); // Withdraw from vault 1
        vaultManager.executeSubscriptions{value: 2 ether}(); 
        (, uint256 balance) = vaultManager.getVault(0); // Get vault 0 details
        assertEq(balance, 0.5 ether, "Vault 0 balance should be 0 ether after deposit subscription execution");
        (, balance) = vaultManager.getVault(1); // Get vault 1 details
        assertEq(balance, 0 ether, "Vault 1 balance should be 0 ether after withdraw subscription execution");
        (, balance) = vaultManager.getVault(2); // Get vault 2 details
        assertEq(balance, 0.4 ether, "Vault 2 balance should be 0.5 ether after transfer subscription execution since it has insufficient funds");
    }
    // This tests if the time interval is working, should execute normally at first, but fail after 1 day
    function testExecuteSubscriptionTimeInterval() public{
        setUpSubscriptions(); // Set up subscriptions
        vaultManager.executeSubscriptions{value: 2 ether}(); 
        vm.warp(1 days);
        vaultManager.deposit{value: 0.5 ether}(1);
        vaultManager.deposit{value: 0.5 ether}(2);
        vaultManager.executeSubscriptions{value: 2 ether}(); 
        (, uint256 balance) = vaultManager.getVault(0); // Get vault 0 details
        assertEq(balance, 0.5 ether, "Vault 0 balance should be 0.5 ether after deposit subscription execution");
        (, balance) = vaultManager.getVault(1); // Get vault 1 details
        assertEq(balance, 0.5 ether, "Vault 1 balance should be 0.5 ether after withdraw subscription execution");
        (, balance) = vaultManager.getVault(2); // Get vault 2 details
        assertEq(balance, 0.5 ether, "Vault 2 balance should be 0.5 ether after transfer subscription execution since it has insufficient funds");

    }
    /*////////////////////////////////////////// 
        Testing getSubscription function
    *////////////////////////////////////////// 
    // Tests getSubscription with valid subscription ID
    function testGetSubscription() public{
        vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        uint256 vaultId = 0; // Alice's vault ID
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        uint256 subType = 2;
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        uint256 subID = 0;
        (uint256 id, address owner, uint256 amount2, uint256 interval2, address recipient2, uint256 subType2, bool active) = vaultManager.getSubscription(subID);
        assertEq(id, 0, "Vault ID should be 0");
        assertEq(owner, alice, "Owner should be Alice"); 
        assertEq(amount2, 0.5 ether, "Amount should be 0.5 ether");
        assertEq(interval2, 1 weeks, "Interval should be 1 weeks");
        assertEq(recipient2, bob, "Recipient should be Bob");
        assertEq(subType2, 2, "Subscription type should be 2-Transfer");
        assertEq(active, true, "Subscription should be active");
    }
    // Test getSubscription with invalid subscription ID
    function testGetSubscriptionInvalidId() public{
        vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        uint256 vaultId = 0; // Alice's vault ID
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        uint256 subType = 2;
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        uint256 subID = 1;
        vm.expectRevert("Subscription does not exist"); // Expect revert for non-existent subscription
        vaultManager.getSubscription(subID); // Get the subscription
    }
    /*////////////////////////////////////////// 
        Testing getMySubscriptions function
    *////////////////////////////////////////// 
    // Tests getMySubscriptions with multiple subscriptions
    function testgetMySubscriptions() public{
        vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        uint256 vaultId = 0; // Alice's vault ID
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        uint256 subType = 2;
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        uint256[] memory mySubs = vaultManager.getMySubscriptions();
        uint256[] memory expected = new uint256[](3); // Create a dynamic memory array of size 3
        expected[0] = 0;
        expected[1] = 1;
        expected[2] = 2;
        assertEq(mySubs.length, expected.length, "Array lengths do not match");
        for (uint256 i = 0; i < mySubs.length; i++) {
            assertEq(mySubs[i], expected[i], "Array elements do not match");
        }
    }
    // Tests case for when mySubscriptions is empty
    function testgetMySubscriptionsEmpty() public{
        vm.startPrank(alice);
        uint256[] memory mySubs = vaultManager.getMySubscriptions();
        assertEq(mySubs.length, 0, "Array length should be 0");
    }
    /*////////////////////////////////////////// 
        Testing getSubscriptionsLength function
    *////////////////////////////////////////// 
    function testGetSubscriptionsLengthEmpty() public view{
        assertEq(vaultManager.getSubscriptionsLength(), 0, "Array length should be 0");
    }
    // Tests getSubscriptionsLength with multiple subscriptions
    function testGetSubscriptionsLength() public{
         vm.startPrank(alice);
        vaultManager.addVault(); // Alice adds a vault
        uint256 vaultId = 0; // Alice's vault ID
        uint256 amount = 0.5 ether; // Amount to deposit, withdraw, and transfer
        uint256 interval = 1 weeks; // Interval for the subscription
        address recipient = bob; // Recipient for the transfer
        uint256 subType = 2;
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        vaultManager.createSubscription(vaultId, amount, interval, recipient, subType);
        assertEq(vaultManager.getSubscriptionsLength(), 3, "Array length should match");
    }
}