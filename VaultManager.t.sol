// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TaskManager} from "../src/TaskManager.sol";

contract TaskManagerTest is Test {

    TaskManager public taskManager;
    address public alice;
    address public bob;

    function setUp() public {
        taskManager = new TaskManager();
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");
    }


    function testInitialConditions() public {
        uint256 tasksLength = taskManager.getTasksLength();
        assertEq(tasksLength, 0);
    }


    function testSingleTask() public {
        // 1. Pretend to be someone, Alice.
        // 2. Alice adds a task to the task manager.
        // 3. Assert: there is now 1 task in the task manager.

        vm.prank(alice); // for the next line, pretend to be Alice
        taskManager.addTask("Wash the dishes", TaskManager.Status.Todo);
        uint256 tasksLength = taskManager.getTasksLength();
        assertEq(tasksLength, 1);

        // 4. Alice tries to update the status of the task.
        // 5. Check that the status did indeed update.
        vm.prank(alice);
        taskManager.updateStatus(0, TaskManager.Status.Done);
        ( , TaskManager.Status updatedStatus, ) = taskManager.getTask(0);
        assertTrue(updatedStatus == TaskManager.Status.Done);
    }

    function testMultipleTasks() public {
        // 1. Pretend to be Alice and add a task.
        // 2. Pretend to be Bob and create another task.
        // 3. Pretend to be Alice again and create a final task.
        // 4. Assert that there are 3 tasks.

        vm.prank(alice);
        taskManager.addTask("Task #1", TaskManager.Status.Doing);

        vm.prank(bob);
        taskManager.addTask("Task #2", TaskManager.Status.Canceled);

        vm.prank(alice);
        taskManager.addTask("Task #3", TaskManager.Status.Todo);

        uint256 tasksLength = taskManager.getTasksLength();
        assertEq(tasksLength, 3);

        // 5. Assert that Alice has 2 tasks.
        // 6. Assert that Bob has 1 tasks.

        vm.prank(alice);
        uint256[] memory aliceTasks = taskManager.getMyTasks();

        vm.prank(bob);
        uint256[] memory bobTasks = taskManager.getMyTasks();

        assertEq(aliceTasks.length, 2);
        assertEq(bobTasks.length, 1);
    }

}
