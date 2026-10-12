public with sharing class TaskManagerController {

    @AuraEnabled(cacheable=true)
    public static List<Task> getTasks() {
        return [
            SELECT Id,
                   Subject,
                   ActivityDate,
                   Status,
                   Priority,
                   Description
            FROM Task
            WHERE OwnerId = :UserInfo.getUserId()
            ORDER BY ActivityDate ASC NULLS LAST, CreatedDate DESC
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static Task createTask(
        String subject,
        Date dueDate,
        String priority,
        String description
    ) {
        Task taskRecord = new Task(
            Subject = subject,
            ActivityDate = dueDate,
            Status = 'Not Started',
            Priority = priority,
            Description = description,
            OwnerId = UserInfo.getUserId()
        );

        insert taskRecord;

        return taskRecord;
    }

    @AuraEnabled
    public static Task updateTask(
        Id taskId,
        String subject,
        Date dueDate,
        String status,
        String priority,
        String description
    ) {
        Task taskRecord = [
            SELECT Id,
                   Subject,
                   ActivityDate,
                   Status,
                   Priority,
                   Description
            FROM Task
            WHERE Id = :taskId
            LIMIT 1
        ];

        taskRecord.Subject = subject;
        taskRecord.ActivityDate = dueDate;
        taskRecord.Status = status;
        taskRecord.Priority = priority;
        taskRecord.Description = description;

        update taskRecord;

        return taskRecord;
    }

    @AuraEnabled
    public static void deleteTask(Id taskId) {
        Task taskRecord = [
            SELECT Id
            FROM Task
            WHERE Id = :taskId
            LIMIT 1
        ];

        delete taskRecord;
    }
}