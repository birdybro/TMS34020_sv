# Open research questions

| ID | Question | Impact | Next evidence |
|---|---|---|---|
| OQ-0001 | What are the exact package top markings/date codes on production Battletoads boards? | Selects original versus A-revision timing | High-resolution board photo with readable GSP marking |
| OQ-0002 | What are the exact package top markings/date codes on Revolution X board revisions? | Selects original versus A-revision timing | High-resolution board photos correlated with 5770-13534 revisions |
| OQ-0003 | Was a standalone SMJ34020 (non-A) released, and how did it differ from commercial TMS34020? | Device matrix and revision selector | Original TI military data sheet/order catalog |
| OQ-0004 | Is there a separate SMJ34020A versus SM34020A functional errata set? | Military/high-reliability behavior | TI errata/qualification publications |
| OQ-0005 | What is the publication number and latest revision of TMS34020/TMS34020A silicon errata? | Architectural/timing correctness | TI archive/catalog or paper scan |
| OQ-0006 | What revisions and content deltas distinguish the SPVU004 and SPVU020 code-generation tool guides? | Assembler/COFF syntax | Title/copyright pages and tables of contents for both identifiers |
| OQ-0007 | Which documented instruction-cycle cases vary with cache, overlap, bus size, page mode and A clock stretch? | Cycle-accuracy plan | Chapter 5/8/13/14 extraction into timing database |
| OQ-0008 | Does either target game enable CONFIG.CSE clock stretch? | Board timing and default variant | Device marking plus boot-code/local-ROM trace |
| OQ-0009 | What are the cache refill fault/retry, interrupt checkpoint, `SIZE16`, page-mode, reset-time SSA-match, and exact local-bus phase rules? | Cache correctness, restartability, bus traces, and sequencer timing | User's Guide chapters 5, 6, 8, 13–15; data-sheet timing; errata |
