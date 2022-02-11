# Purpose

This pattern is useful for when a business process needs to track inputs from
multiple different places. It allows for a main workflow to track the overall progress
and maintain the journey status. Each input is handled by a separate workflow which
receives the input and then signals that input to the main workflow to update its
state. The main workflow then responds back to the other workflow which can exit and
return a complex value to its caller. 

The caller could potentially Query the main workflow to get results. Having these secondary
workflows return a response to the caller seems cleaner and more logical.

The flow of calls is outlined in the diagram below.

![Flow Diagram](flow.png)
# Execution

Open two shells / terminal windows. In one, execute:
```shell
ruby worker/worker.rb
```
In the second, execute:
```shell
ruby ui/main.rb
```
In the shell running `ui` it will ask a series of questions. Answer the questions and the
program will send the appropriate signals around to complete the process. Upon completion it
prints a success message.
