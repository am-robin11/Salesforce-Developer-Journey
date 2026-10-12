import { LightningElement, wire } from 'lwc';

import getTasks from '@salesforce/apex/TaskManagerController.getTasks';
import createTask from '@salesforce/apex/TaskManagerController.createTask';
import updateTask from '@salesforce/apex/TaskManagerController.updateTask';
import deleteTask from '@salesforce/apex/TaskManagerController.deleteTask';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class TaskManager extends LightningElement {
    tasks = [];

    subject = '';
    dueDate = '';
    priority = 'Normal';
    status = 'Not Started';
    description = '';

    editingTaskId = null;

    wiredTasksResult;

    priorityOptions = [
        { label: 'High', value: 'High' },
        { label: 'Normal', value: 'Normal' },
        { label: 'Low', value: 'Low' }
    ];

    statusOptions = [
        { label: 'Not Started', value: 'Not Started' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Waiting on someone else', value: 'Waiting on someone else' },
        { label: 'Deferred', value: 'Deferred' }
    ];

    @wire(getTasks)
    wiredTasks(result) {
        this.wiredTasksResult = result;

        if (result.data) {
            this.tasks = result.data;
        } else if (result.error) {
            this.showToast(
                'Error',
                this.getErrorMessage(result.error),
                'error'
            );
        }
    }

    get isEditing() {
        return this.editingTaskId !== null;
    }

    get formTitle() {
        return this.isEditing ? 'Edit Task' : 'Create Task';
    }

    get saveButtonLabel() {
        return this.isEditing ? 'Update Task' : 'Add Task';
    }

    handleChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }

    async handleSave() {
        if (!this.subject.trim()) {
            this.showToast(
                'Validation Error',
                'Subject is required.',
                'error'
            );
            return;
        }

        try {
            if (this.isEditing) {
                await updateTask({
                    taskId: this.editingTaskId,
                    subject: this.subject,
                    dueDate: this.dueDate || null,
                    status: this.status,
                    priority: this.priority,
                    description: this.description
                });

                this.showToast(
                    'Success',
                    'Task updated successfully.',
                    'success'
                );
            } else {
                await createTask({
                    subject: this.subject,
                    dueDate: this.dueDate || null,
                    priority: this.priority,
                    description: this.description
                });

                this.showToast(
                    'Success',
                    'Task created successfully.',
                    'success'
                );
            }

            this.resetForm();

            await refreshApex(this.wiredTasksResult);

        } catch (error) {
            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );
        }
    }

    handleEdit(event) {
        const taskId = event.currentTarget.dataset.id;

        const task = this.tasks.find(
            item => item.Id === taskId
        );

        if (!task) {
            return;
        }

        this.editingTaskId = task.Id;
        this.subject = task.Subject || '';
        this.dueDate = task.ActivityDate || '';
        this.priority = task.Priority || 'Normal';
        this.status = task.Status || 'Not Started';
        this.description = task.Description || '';
    }

    async handleComplete(event) {
        const taskId = event.currentTarget.dataset.id;

        const task = this.tasks.find(
            item => item.Id === taskId
        );

        if (!task) {
            return;
        }

        try {
            await updateTask({
                taskId: task.Id,
                subject: task.Subject,
                dueDate: task.ActivityDate || null,
                status: 'Completed',
                priority: task.Priority,
                description: task.Description
            });

            this.showToast(
                'Success',
                'Task marked as completed.',
                'success'
            );

            await refreshApex(this.wiredTasksResult);

        } catch (error) {
            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );
        }
    }

    async handleDelete(event) {
        const taskId = event.currentTarget.dataset.id;

        try {
            await deleteTask({
                taskId
            });

            this.showToast(
                'Success',
                'Task deleted.',
                'success'
            );

            await refreshApex(this.wiredTasksResult);

        } catch (error) {
            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );
        }
    }

    handleCancel() {
        this.resetForm();
    }

    resetForm() {
        this.editingTaskId = null;
        this.subject = '';
        this.dueDate = '';
        this.priority = 'Normal';
        this.status = 'Not Started';
        this.description = '';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }

        if (error?.message) {
            return error.message;
        }

        return 'An unexpected error occurred.';
    }
}