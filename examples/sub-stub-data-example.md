600a-task-routes
# Task Routes

## Description

**Ignore Task Routes** is a checkbox option found under **Advanced Scheduling Configuration → Data Loading Options → Task Routes** in PrintFlow/PrintFlow 4D. When enabled, it instructs the PrintFlow scheduling engine to completely disregard all task route information that has been transmitted from the MIS (e.g., Planner, Technique) during scheduling, rescheduling, and optimization operations.

Task Routes in PrintFlow represent alternative cost center assignments for individual production steps within a job. The MIS sends route data as part of the job XML, with each route carrying a `RouteID` and `RoutePreference` value. Under normal operation, the scheduling engine evaluates these routes and selects the most optimal cost center alternative for each task based on capacity, urgency, and switchover considerations. When **Ignore Task Routes** is checked, the engine bypasses this evaluation entirely and treats all tasks as though no route restrictions exist — effectively making every eligible cost center available for scheduling based solely on limit rules and parallel cost center membership.

## How It Works

When **Ignore Task Routes** is unchecked (default behavior), the scheduling engine:

1. Reads route data from the `PF_TASKS` table (fields `RouteID` and `RoutePreference`).
2. Groups tasks by `RouteID` to identify sets of alternative production steps.
3. Selects one route per route group based on optimization scoring (capacity availability, urgency, switchover cost).
4. Schedules only the tasks belonging to the chosen route; tasks on non-selected routes remain inactive/unscheduled.

When **Ignore Task Routes** is checked:

1. The engine skips all route evaluation logic.
2. All tasks are treated as independent — no route grouping or selection occurs.
3. Tasks are scheduled based on cost center eligibility (limit rules, parallel CC membership, and general scheduling rules) without regard to which route they belong to.
4. The scheduler behaves as if the MIS sent no route information at all.

## Effects on Scheduling

- **Wider cost center pool**: Tasks may be placed on any cost center that satisfies limit rules, not just those specified in the route data. This can improve load balancing across the shop floor.
- **Loss of MIS-driven routing logic**: The carefully curated alternative routes from the MIS (which encode production method feasibility, machine capabilities, tooling requirements, etc.) are completely bypassed. This may lead to tasks being scheduled on machines that cannot technically produce them if limit rules are not sufficiently comprehensive.
- **No route selection decision**: The engine does not choose between Route A and Route B — it simply ignores that routes exist. If multiple route alternatives created duplicate tasks for the same production step, all of them may appear in the schedule rather than just the selected route's tasks.
- **Potential scheduling conflicts**: Tasks that were designed as mutually exclusive alternatives (e.g., print on Press 1 via Route A *or* Press 2 via Route B) may both get scheduled if routes are ignored and both cost centers are eligible.
- **Faster scheduling runs**: Bypassing route evaluation reduces computational overhead, which may slightly speed up optimization for large datasets with many route alternatives.

## How to Configure

1. Navigate to **Settings → Scheduling Configuration** (or in classic PrintFlow: **File → Configure System**).
2. Go to **Advanced Scheduling Configuration → Data Loading Options**.
3. Locate the **Task Routes** section.
4. Check or uncheck **Ignore Task Routes**.
5. Click **Apply** / **OK** or **Save** to commit the change.
6. The setting takes effect on the next scheduling/rescheduling/optimization run.

### Per-Plant vs. Global

In PrintFlow 4D, scheduling configuration can be customized at the plant level. If the loaded plant has customized settings, the plant-level value is used; otherwise, the global default applies.

## Guidance & Best Practices

- **Leave unchecked** (default) when the MIS provides reliable, well-maintained route data that reflects actual machine capabilities. This is the expected configuration for Planner and Technique integrations.
- **Check this option** as a troubleshooting or transitional measure — for example, when route data is known to be incomplete, incorrect, or out of date, and is causing tasks to be incorrectly constrained to a small set of machines.
- **Do not use as a permanent workaround** for poorly defined routes. Instead, fix the route data in the MIS and keep this unchecked so the scheduling engine can make informed decisions.
- If you enable this setting, ensure that your **cost center limit rules** are comprehensive enough to prevent tasks from being assigned to machines that cannot physically produce them. Without route constraints, limit rules become the only guardrail.
- When used in combination with Parallel Cost Centers (the Radius integration model), this setting is less impactful because Radius uses Parallel CCs rather than Task Routes for alternative cost center selection. However, in environments where both mechanisms are present, ignoring routes may produce unexpected results.

## Practical Example

A commercial printing operation uses Technique as its MIS. Technique sends job data to PrintFlow 4D with alternative routes: Route A schedules a folding task on Folder-1, while Route B specifies Folder-2. Under normal operation, PrintFlow evaluates both routes and selects the one that best fits the current schedule.

If **Ignore Task Routes** is checked, PrintFlow disregards both route specifications. If Folder-1 and Folder-2 are members of a Folding Parallel Cost Center, the distribution engine handles placement. If they are not members of a parallel CC, the task could end up on any eligible cost center, potentially including machines that should not receive that work.

The scheduler notices that jobs are being placed on incorrect machines. After investigation, they discover that Ignore Task Routes was enabled during a previous troubleshooting session and never reverted. Unchecking the option and rescheduling restores the MIS-driven routing behavior.

## Interactions with Other Settings

- **Leave tasks that cannot run on any cost center because of limit violations unscheduled**: When routes are ignored and limit rules are insufficient, tasks may still fail to schedule. This setting controls whether those tasks are left unscheduled or forced onto an undefined CC.
- **Allow tasks that have been placed on to non-allowed CC by hand to remain there on rescheduling**: This Planner/Monarch-specific option overrides route information with manual placement. When Ignore Task Routes is also enabled, both route constraints and route-override logic are effectively neutralized.
- **Use all available CCs**: When checked, the parallel distribution engine uses all available member cost centers rather than minimizing. Combined with Ignore Task Routes, this maximizes cost center spread but removes all MIS-directed routing intelligence.
- **Cost Center Limit Rules**: Become the primary (and only) means of preventing invalid machine assignments when routes are ignored. Their importance increases significantly.
- **Parallel Cost Center configuration**: For Radius integrations, Parallel CCs are the primary mechanism for alternative cost center selection (not Task Routes). Ignoring routes has minimal impact in a pure Radius/Parallel CC setup.

## Important Notes

- This setting appears in the **Upgrading to PrintFlow 4D** comparison tables as a configurable option under Advanced Scheduling Configuration → Data Loading Options, confirming it is carried forward into PrintFlow 4D from classic PrintFlow.
- The setting is a global/plant-level toggle — it cannot be applied selectively to individual jobs or tasks.
- Route data is preserved in the database even when this setting is enabled; unchecking the setting restores route-aware scheduling without requiring a data reload from the MIS.

### Radius Integration Tie-In

In the Radius integration model, alternative cost center selection is handled via **Parallel Cost Centers** rather than Task Routes. Radius defines work centers as Normal, Parallel, or Tandem, and exports them to PrintFlow via XML. The Parallel CC mechanism groups interchangeable machines so PrintFlow can distribute load across them. Because Radius does not natively use the Task Routes concept (which originated with Planner/Technique), the **Ignore Task Routes** setting has limited direct impact in a pure Radius environment. However, if the Radius integration is evolving toward BOD-based data exchange (as with PrintFlow 4D), and route data begins to appear in the data stream, this setting becomes relevant as a control for whether that route data is honored.

---

600b-task-routes
# Task Routes

## Description

**Create Routes On All Alternatives** is a checkbox option found under **Advanced Scheduling Configuration → Data Loading Options → Task Routes** in PrintFlow/PrintFlow 4D. When enabled, it instructs the system to automatically generate task route entries for every alternative cost center associated with a task during data loading, even when the MIS has not explicitly provided route data for each alternative. This effectively ensures that the scheduling engine has full route coverage across all alternative production paths, maximizing the optimizer's flexibility when selecting cost centers.

Where the companion setting **Ignore Task Routes** tells the engine to disregard routes entirely, **Create Routes On All Alternatives** takes the opposite approach: it ensures routes are created comprehensively so that the engine has the maximum number of explicitly defined alternatives to evaluate.

## How It Works

When **Create Routes On All Alternatives** is unchecked (default behavior):

1. PrintFlow loads only the route data explicitly provided by the MIS in the job XML.
2. If the MIS sends a task with one calculated route and two alternative routes, the engine works with exactly those three routes.
3. Any cost centers not represented in the route data are not considered as alternatives during scheduling, even if they are technically capable of producing the task.

When **Create Routes On All Alternatives** is checked:

1. During data loading, PrintFlow inspects each task's assigned cost center and identifies all alternative cost centers — including Parallel CC members and other eligible machines defined through cost center configuration.
2. For each alternative cost center that does not already have an explicit route entry from the MIS, PrintFlow generates a synthetic route record.
3. The scheduling engine then has a complete set of route alternatives to evaluate, covering every machine that could potentially produce the task.
4. This ensures that optimization and rescheduling consider the full breadth of production options, not just those the MIS happened to include.

## Effects on Scheduling

- **Maximized scheduling flexibility**: The optimizer evaluates a broader set of cost center alternatives, potentially finding better solutions for load leveling, bottleneck relief, and switchover minimization.
- **Compensates for incomplete MIS route data**: If the MIS does not generate route alternatives for every possible machine (e.g., due to configuration gaps, data maintenance issues, or limited route generation logic), this setting fills the gaps automatically.
- **Increased data volume**: Generating additional route records increases the size of the in-memory dataset. For environments with many tasks and many cost centers, this can increase memory usage and scheduling computation time.
- **May override MIS intent**: The MIS may intentionally limit routes to a subset of capable machines (e.g., only machines with specific tooling, only machines in a particular cell). Creating routes on all alternatives bypasses this intentional restriction, potentially scheduling tasks on machines the MIS excluded for good reason.
- **Setup duration behavior on generated routes**: When routes are auto-generated, the setup duration values associated with them may default to zero or inherit from the cost center, since the MIS did not provide specific setup times for those alternatives. This was observed in Technique integration scenarios where calculated routes carried setup times but auto-generated alternative routes showed setup time as "0".

## How to Configure

1. Navigate to **Settings → Scheduling Configuration** (or in classic PrintFlow: **File → Configure System**).
2. Go to **Advanced Scheduling Configuration → Data Loading Options**.
3. Locate the **Task Routes** section.
4. Check or uncheck **Create Routes On All Alternatives**.
5. Click **Apply** / **OK** or **Save** to commit the change.
6. The setting takes effect on the next data load or scan-for-data operation.

### Per-Plant vs. Global

As with other Advanced Scheduling Configuration options in PrintFlow 4D, this can be set at the global level or overridden at the plant level.

## Guidance & Best Practices

- **Enable this setting** when the MIS provides limited route alternatives but the shop floor has many interchangeable machines. This is particularly useful during initial integration phases or when MIS route configuration is incomplete.
- **Leave unchecked** when the MIS provides comprehensive, well-maintained route data that intentionally restricts alternatives to technically feasible machines. In this case, auto-generating additional routes may undermine the MIS's routing intelligence.
- **Use in conjunction with robust limit rules**: If you enable this setting, ensure cost center limit rules are properly configured to prevent tasks from being assigned to machines that cannot physically produce them. The auto-generated routes do not carry MIS-validated feasibility checks.
- **Monitor setup durations**: Auto-generated routes may not carry accurate setup time data. If setup time accuracy is critical to your schedule, verify that the generated routes inherit reasonable defaults or configure the "Ignore planned task setup duration" option appropriately.
- **Consider performance impact**: In large environments (hundreds of cost centers, thousands of tasks), generating routes for all alternatives can increase scheduling time. Test the impact before enabling in production.

## Practical Example

A flexible packaging plant uses Technique as its MIS. Technique sends jobs with a calculated route on the primary flexo press and two alternative routes. However, the plant has five flexo presses in a parallel cost center group, and Technique only generates alternatives for presses explicitly configured in the routing. The remaining two presses are technically capable but not represented in the route data.

With **Create Routes On All Alternatives** checked, PrintFlow generates route entries for the two missing presses during data loading. When the optimizer runs, it evaluates all five presses and distributes the workload more evenly, relieving a bottleneck on the two presses that previously received all the work.

Without this setting, the scheduler would need to either manually configure the missing routes in the MIS or accept the suboptimal distribution.

## Interactions with Other Settings

- **Ignore Task Routes**: These two settings are functionally opposing strategies. Ignore Task Routes discards all route data; Create Routes On All Alternatives expands it. If both are enabled simultaneously, Ignore Task Routes takes precedence — routes are generated but then ignored by the engine, making the generation pointless.
- **Parallel Cost Center membership**: The auto-generation logic uses Parallel CC member lists as a primary source for identifying alternative cost centers. Properly configured Parallel CCs are essential for this setting to produce useful results.
- **Cost Center Limit Rules**: Limit rules serve as a safety net when auto-generated routes include machines that are technically ineligible. Without adequate limits, tasks may be scheduled on inappropriate equipment.
- **Ignore planned task setup duration**: Since auto-generated routes may carry zero or default setup times, this companion setting can be used to discard setup duration data entirely and rely on switchover rules instead.
- **Leave tasks that cannot run on any cost center because of limit violations unscheduled**: Relevant when auto-generated routes place tasks on cost centers that fail limit checks — tasks that fail all alternatives remain in the To-Do List.

## Important Notes

- This setting affects the **data loading phase**, not the scheduling engine directly. Routes are generated when data is loaded or refreshed (Read from Database / Scan for Data), and the scheduler then uses whatever routes exist at scheduling time.
- Auto-generated routes persist only in the in-memory dataset and are regenerated on each data load. They are not written back to the MIS or permanently stored in the PrintFlow database as MIS-originated routes.
- In the Technique integration, there is a known interaction where Technique sends setup times on calculated routes but sends "0" for alternative routes. When Create Routes On All Alternatives generates additional routes, those also carry "0" for setup time, which may skew setup-related scheduling calculations.

### Radius Integration Tie-In

In the Radius integration model, alternative cost center flexibility is primarily achieved through **Parallel Cost Centers**. Radius defines work centers as Normal or Parallel and exports them to PrintFlow. Parallel CCs inherently provide multi-machine distribution without requiring Task Routes. However, **Create Routes On All Alternatives** can still be useful in Radius environments in two scenarios:

1. **Hybrid configurations**: If the Radius environment has evolved to include route data (e.g., through BOD-based integration in PrintFlow 4D), this setting ensures all parallel CC members are represented as route alternatives.
2. **Tooling integration**: When tools are linked to specific work centers via Radius estimating, the auto-generated routes ensure that tooling availability checks are performed across all eligible machines, not just those in the MIS-provided routes. This ties into the broader tool allocation workflow where tool changes may occur based on the parent path change (e.g., digital vs. short-run flexo route).

Radius exports work center data (Normal, Parallel, Tandem types) via XML to PrintFlow. The Parallel Work Center Members window in Radius defines which actual machines belong to each parallel group. When Create Routes On All Alternatives is enabled, PrintFlow uses this parallel membership data to populate routes across all member machines, bridging the gap between Radius's Parallel CC model and PrintFlow's Task Routes model.

---
index
## Summary

Both **Ignore Task Routes** and **Create Routes On All Alternatives** are configuration options within the same **Task Routes** subsection of **Advanced Scheduling Configuration → Data Loading Options**. They are *not* duplicates — they represent opposite ends of a spectrum for how the scheduling engine handles task route data:

| Aspect | Ignore Task Routes | Create Routes On All Alternatives |
|---|---|---|
| **Purpose** | Disables route-based cost center selection entirely | Expands route data to cover all possible cost center alternatives |
| **When it acts** | At scheduling/optimization time | At data loading time |
| **Effect on routes** | Discards/bypasses all route data | Generates additional route records for missing alternatives |
| **Net result** | All eligible CCs considered, no route preference | All eligible CCs explicitly represented as routes with preferences |
| **Primary use case** | Troubleshooting, incomplete/broken route data, non-route MIS integrations | MIS provides limited alternatives but more machines are available |
| **Risk** | Tasks may go to wrong machines without adequate limit rules | Over-generation may override MIS intent; setup times may be inaccurate |
| **Radius relevance** | Low — Radius uses Parallel CCs, not Task Routes | Moderate — bridges Parallel CC membership into route records |

Together, these settings give PrintFlow administrators fine-grained control over how MIS-provided route intelligence is applied during scheduling. In environments where the MIS is the authority on machine feasibility, both should typically be left in their default states (unchecked). In transitional, troubleshooting, or hybrid integration scenarios, they provide essential flexibility.

