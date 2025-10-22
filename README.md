KPI Performance and Outlier Management in a Call Center Environment Using Dynamic Performance Targets and Six Sigma Lean Approach

Step 1: Assigning a Performance Target The first step involves assigning a performance target for a project, business line, or skill level using a 50% inlier approach, or in other words, the median of the defined previous period's performance.

The process is as follows:

Calculate the AHT performance over the last 6 months, grouped by employee.
Filter the data to include only those with a tenure of >= 90 days. For example, if an employee started 4 months ago, only the last 2 months' results would be included in the AHT calculation.
This approach ensures a balanced target setting for the KPI. This condition is applicable only if there is no target delivered by the client.

Step 2: Creating a Dynamic Goal The second step is creating a dynamic goal for each employee, skill, line of business (LOB), or service breakdown. This step depends on your business model; you might have one target for all breakdowns or separate targets for each.

Dynamic AHT Goal Since AHT may differ from skill to skill or support group to support group, analyzing AHT alone can be misleading, especially for outlier management. For instance, while one service might require 500 seconds of optimal handling time, another could require 1000 seconds due to the nature of the service. Therefore, we need another KPI to measure AHT performance over the AHT target. We will call this KPI "AHT Attainment" or "Attainment."

Let's start by defining our fields:

Date: Date field in our dataset as Date format
Employee: Unique identifier of Employee
SkillID: Unique identifier of the Skills. You can replace this value with anything that would fit your needs better, e.g., Language, LOB, Support group, Activity group, etc.
TenureDays: The days past since the employee joined the production. This parameter can vary based on your business model, e.g., it could refer to the day the employee got hired or joined the project or after the first New Hire process, etc.
Calls: The number of interactions that the employee handled, which could be cases, tickets, etc.
Total Handling Time: The total time spent handling the workload.
AHT: Average time spent on handling the workload, in other words, TotalHandlingTime/Calls.




