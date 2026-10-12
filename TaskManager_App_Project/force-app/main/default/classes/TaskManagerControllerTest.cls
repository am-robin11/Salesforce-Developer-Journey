@IsTest
private class TaskManagerControllerTest {

    @IsTest
    static void testGetTasks() {
        Task taskRecord = new Task(
            Subject = 'Test Task',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today()
        );

        insert taskRecord;

        Test.startTest();

        List<Task> results = TaskManagerController.getTasks();

        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Test Task', results[0].Subject);
    }

    @IsTest
    static void testCreateTask() {
        Test.startTest();

        Task createdTask = TaskManagerController.createTask(
            'Created Task',
            Date.today().addDays(3),
            'High',
            'Created from Apex test'
        );

        Test.stopTest();

        Task storedTask = [
            SELECT Subject,
                   ActivityDate,
                   Status,
                   Priority,
                   Description
            FROM Task
            WHERE Id = :createdTask.Id
        ];

        System.assertEquals('Created Task', storedTask.Subject);
        System.assertEquals(Date.today().addDays(3), storedTask.ActivityDate);
        System.assertEquals('Not Started', storedTask.Status);
        System.assertEquals('High', storedTask.Priority);
        System.assertEquals('Created from Apex test', storedTask.Description);
    }

    @IsTest
    static void testUpdateTask() {
        Task taskRecord = new Task(
            Subject = 'Original Task',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today()
        );

        insert taskRecord;

        Test.startTest();

        Task updatedTask = TaskManagerController.updateTask(
            taskRecord.Id,
            'Updated Task',
            Date.today().addDays(5),
            'In Progress',
            'High',
            'Updated description'
        );

        Test.stopTest();

        System.assertEquals('Updated Task', updatedTask.Subject);
        System.assertEquals('In Progress', updatedTask.Status);
        System.assertEquals('High', updatedTask.Priority);
    }

    @IsTest
    static void testDeleteTask() {
        Task taskRecord = new Task(
            Subject = 'Task To Delete',
            Status = 'Not Started',
            Priority = 'Normal'
        );

        insert taskRecord;

        Test.startTest();

        TaskManagerController.deleteTask(taskRecord.Id);

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Task WHERE Id = :taskRecord.Id]
        );
    }
}